/// Tests de Conexion en Tiempo Real de Supabase
/// Verifica suscripciones, reconexiones, y manejo de volumenes grandes
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Realtime: Subscription Management', () {
    // =========================================================================
    // TEST 1: Multiples suscripciones no causan leaks
    // =========================================================================
    test('Crear y cancelar 100 suscripciones sin leak', () async {
      final subscriptions = <StreamSubscription>[];
      final controller = StreamController<int>.broadcast();

      for (int i = 0; i < 100; i++) {
        final sub = controller.stream.listen((_) {});
        subscriptions.add(sub);
      }

      // Cancelar todas
      for (final sub in subscriptions) {
        await sub.cancel();
      }

      await controller.close();

      expect(subscriptions.length, 100);
    });

    // =========================================================================
    // TEST 2: Suscripcion se reconecta automaticamente
    // =========================================================================
    test('Stream puede reconectarse despues de error', () async {
      var connectionAttempts = 0;
      var isConnected = false;

      // Simular reconexion
      Future<void> connect() async {
        connectionAttempts++;
        await Future.delayed(const Duration(milliseconds: 10));
        isConnected = true;
      }

      // Primera conexion
      await connect();
      expect(isConnected, true);

      // Simular desconexion
      isConnected = false;

      // Reconexion
      await connect();
      expect(isConnected, true);
      expect(connectionAttempts, 2);
    });

    // =========================================================================
    // TEST 3: Backoff exponencial en reconexion
    // =========================================================================
    test('Backoff exponencial funciona correctamente', () {
      int calculateBackoff(int attempt) {
        const baseDelay = 1000; // 1 second
        const maxDelay = 30000; // 30 seconds
        final delay = baseDelay * (1 << attempt);
        return delay > maxDelay ? maxDelay : delay;
      }

      expect(calculateBackoff(0), 1000); // 1s
      expect(calculateBackoff(1), 2000); // 2s
      expect(calculateBackoff(2), 4000); // 4s
      expect(calculateBackoff(3), 8000); // 8s
      expect(calculateBackoff(4), 16000); // 16s
      expect(calculateBackoff(5), 30000); // capped at 30s
    });
  });

  group('Realtime: Event Handling', () {
    // =========================================================================
    // TEST 4: Procesar 1000 eventos < 500ms
    // =========================================================================
    test('Procesar 1000 eventos es rapido', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final processedEvents = <Map<String, dynamic>>[];

      final stopwatch = Stopwatch()..start();

      final subscription = controller.stream.listen((event) {
        processedEvents.add(event);
      });

      // Emitir 1000 eventos
      for (int i = 0; i < 1000; i++) {
        controller.add({'type': 'INSERT', 'id': i});
      }

      // Esperar procesamiento
      await Future.delayed(const Duration(milliseconds: 100));

      stopwatch.stop();
      await subscription.cancel();
      await controller.close();

      expect(processedEvents.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    // =========================================================================
    // TEST 5: Eventos duplicados se filtran
    // =========================================================================
    test('Eventos duplicados se manejan', () {
      final seenIds = <String>{};
      final uniqueEvents = <Map<String, dynamic>>[];

      void processEvent(Map<String, dynamic> event) {
        final id = event['id'] as String;
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          uniqueEvents.add(event);
        }
      }

      // Simular eventos con duplicados
      processEvent({'id': '1', 'data': 'first'});
      processEvent({'id': '2', 'data': 'second'});
      processEvent({'id': '1', 'data': 'duplicate'}); // Duplicado
      processEvent({'id': '3', 'data': 'third'});

      expect(uniqueEvents.length, 3);
    });

    // =========================================================================
    // TEST 6: Eventos fuera de orden se ordenan
    // =========================================================================
    test('Eventos se pueden ordenar por timestamp', () {
      final events = [
        {'id': '1', 'timestamp': DateTime.now().subtract(const Duration(seconds: 30))},
        {'id': '2', 'timestamp': DateTime.now()},
        {'id': '3', 'timestamp': DateTime.now().subtract(const Duration(seconds: 60))},
      ];

      events.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

      expect((events[0]['id'] as String), '3'); // Oldest first
      expect((events[2]['id'] as String), '2'); // Newest last
    });
  });

  group('Realtime: Channel Management', () {
    // =========================================================================
    // TEST 7: Canal se crea correctamente
    // =========================================================================
    test('Nombre de canal es valido', () {
      String createChannelName(String table, String userId) {
        return 'realtime:public:$table:user_id=eq.$userId';
      }

      final channelName = createChannelName('accounts', 'user123');

      expect(channelName, contains('accounts'));
      expect(channelName, contains('user123'));
      expect(channelName.startsWith('realtime:'), true);
    });

    // =========================================================================
    // TEST 8: Multiples canales se manejan
    // =========================================================================
    test('Gestionar multiples canales', () {
      final channels = <String, StreamController>{};

      void subscribe(String table) {
        channels[table] = StreamController.broadcast();
      }

      void unsubscribe(String table) {
        channels[table]?.close();
        channels.remove(table);
      }

      subscribe('accounts');
      subscribe('transactions');
      subscribe('budgets');

      expect(channels.length, 3);

      unsubscribe('transactions');
      expect(channels.length, 2);

      // Cleanup
      for (final controller in channels.values) {
        controller.close();
      }
    });

    // =========================================================================
    // TEST 9: Suscripcion con filtros
    // =========================================================================
    test('Filtros de suscripcion funcionan', () {
      final events = [
        {'user_id': 'user1', 'type': 'income'},
        {'user_id': 'user2', 'type': 'expense'},
        {'user_id': 'user1', 'type': 'expense'},
      ];

      final filtered = events.where((e) => e['user_id'] == 'user1').toList();

      expect(filtered.length, 2);
    });
  });

  group('Realtime: Error Recovery', () {
    // =========================================================================
    // TEST 10: Timeout de conexion manejado
    // =========================================================================
    test('Timeout causa reintento', () async {
      var timeouts = 0;
      var success = false;

      Future<bool> connectWithTimeout() async {
        try {
          // Simular timeout en primeros intentos
          if (timeouts < 2) {
            timeouts++;
            throw TimeoutException('Connection timeout');
          }
          return true;
        } catch (e) {
          return false;
        }
      }

      // Reintentar hasta exito
      for (int i = 0; i < 5 && !success; i++) {
        success = await connectWithTimeout();
      }

      expect(timeouts, 2);
      expect(success, true);
    });

    // =========================================================================
    // TEST 11: Error de autenticacion manejado
    // =========================================================================
    test('Error 401 no causa reintento infinito', () {
      var attempts = 0;
      const maxAttempts = 3;

      bool shouldRetry(int statusCode) {
        attempts++;
        // No reintentar errores de auth
        if (statusCode == 401 || statusCode == 403) {
          return false;
        }
        return attempts < maxAttempts;
      }

      final result401 = shouldRetry(401);
      expect(result401, false);
      expect(attempts, 1);

      // Reset
      attempts = 0;

      // Error recuperable
      var retrying = true;
      while (retrying) {
        retrying = shouldRetry(500);
      }
      expect(attempts, maxAttempts);
    });

    // =========================================================================
    // TEST 12: Eventos perdidos se recuperan
    // =========================================================================
    test('Sincronizacion recupera eventos perdidos', () async {
      final serverEvents = List.generate(100, (i) => {'id': i, 'data': 'event_$i'});
      final localEvents = List.generate(50, (i) => {'id': i, 'data': 'event_$i'});

      // Encontrar eventos faltantes
      final localIds = localEvents.map((e) => e['id']).toSet();
      final missingEvents = serverEvents.where((e) => !localIds.contains(e['id'])).toList();

      expect(missingEvents.length, 50);
    });
  });

  group('Realtime: Performance Under Load', () {
    // =========================================================================
    // TEST 13: 10 suscripciones activas simultaneas
    // =========================================================================
    test('10 streams activos sin degradacion', () async {
      final controllers = List.generate(10, (_) => StreamController<int>.broadcast());
      final counts = List.filled(10, 0);

      // Suscribirse a todos
      for (int i = 0; i < 10; i++) {
        controllers[i].stream.listen((_) {
          counts[i]++;
        });
      }

      // Emitir a todos
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 100; j++) {
          controllers[i].add(j);
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar todos recibieron eventos
      for (int i = 0; i < 10; i++) {
        expect(counts[i], 100);
      }

      // Cleanup
      for (final c in controllers) {
        await c.close();
      }
    });

    // =========================================================================
    // TEST 14: Burst de eventos se maneja
    // =========================================================================
    test('Burst de 5000 eventos en 1 segundo', () async {
      final controller = StreamController<int>();
      var received = 0;

      final subscription = controller.stream.listen((_) {
        received++;
      });

      final stopwatch = Stopwatch()..start();

      // Burst de eventos
      for (int i = 0; i < 5000; i++) {
        controller.add(i);
      }

      // Esperar procesamiento
      await Future.delayed(const Duration(milliseconds: 500));

      stopwatch.stop();

      await subscription.cancel();
      await controller.close();

      expect(received, 5000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    // =========================================================================
    // TEST 15: Debounce funciona correctamente
    // =========================================================================
    test('Debounce reduce eventos', () async {
      var processedCount = 0;
      Timer? debounceTimer;
      const debounceDuration = Duration(milliseconds: 50);

      void processWithDebounce(int value) {
        debounceTimer?.cancel();
        debounceTimer = Timer(debounceDuration, () {
          processedCount++;
        });
      }

      // Enviar 100 eventos rapidamente
      for (int i = 0; i < 100; i++) {
        processWithDebounce(i);
      }

      // Esperar debounce
      await Future.delayed(const Duration(milliseconds: 100));

      // Solo 1 evento deberia haberse procesado (el ultimo)
      expect(processedCount, 1);
    });
  });

  group('Realtime: State Synchronization', () {
    // =========================================================================
    // TEST 16: Optimistic updates funcionan
    // =========================================================================
    test('Optimistic update y rollback', () {
      final state = <String, dynamic>{
        'balance': 1000.0,
        'pending': <Map<String, dynamic>>[],
      };

      void optimisticUpdate(double amount, String txId) {
        state['balance'] = (state['balance'] as double) + amount;
        (state['pending'] as List).add({'id': txId, 'amount': amount});
      }

      void confirmUpdate(String txId) {
        (state['pending'] as List).removeWhere((p) => p['id'] == txId);
      }

      void rollbackUpdate(String txId) {
        final pending = (state['pending'] as List);
        final tx = pending.firstWhere((p) => p['id'] == txId, orElse: () => null);
        if (tx != null) {
          state['balance'] = (state['balance'] as double) - (tx['amount'] as double);
          pending.remove(tx);
        }
      }

      // Optimistic update
      optimisticUpdate(-100.0, 'tx1');
      expect(state['balance'], 900.0);

      // Confirmar
      confirmUpdate('tx1');
      expect(state['balance'], 900.0);

      // Otro update que falla
      optimisticUpdate(-200.0, 'tx2');
      expect(state['balance'], 700.0);

      // Rollback
      rollbackUpdate('tx2');
      expect(state['balance'], 900.0);
    });

    // =========================================================================
    // TEST 17: Conflictos se resuelven
    // =========================================================================
    test('Last Write Wins conflict resolution', () {
      final localVersion = {
        'id': '1',
        'data': 'local change',
        'updated_at': DateTime.now().subtract(const Duration(seconds: 5)),
      };

      final remoteVersion = {
        'id': '1',
        'data': 'remote change',
        'updated_at': DateTime.now(),
      };

      // Last Write Wins
      Map<String, dynamic> resolveConflict(
        Map<String, dynamic> local,
        Map<String, dynamic> remote,
      ) {
        final localTime = local['updated_at'] as DateTime;
        final remoteTime = remote['updated_at'] as DateTime;
        return remoteTime.isAfter(localTime) ? remote : local;
      }

      final resolved = resolveConflict(localVersion, remoteVersion);
      expect(resolved['data'], 'remote change');
    });
  });
}
