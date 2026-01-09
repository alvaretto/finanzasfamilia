import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/application/providers/connectivity_provider.dart';
import 'package:finanzas_familiares/application/providers/sync_status_provider.dart';
import 'package:finanzas_familiares/presentation/widgets/sync_status_indicator.dart';

void main() {
  group('SyncStatusIndicator', () {
    Widget createTestWidget({
      SyncState syncState = const SyncState(),
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      bool showLabel = false,
      bool interactive = true,
    }) {
      return ProviderScope(
        overrides: [
          syncStatusProvider.overrideWith(() => _MockSyncStatus(syncState)),
          connectivityNotifierProvider.overrideWith(
            () => _MockConnectivityNotifier(connectivity),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              showLabel: showLabel,
              interactive: interactive,
            ),
          ),
        ),
      );
    }

    testWidgets('muestra icono cloud_done cuando sincronizado', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
      ));

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('muestra icono cloud_off cuando offline', (tester) async {
      await tester.pumpWidget(createTestWidget(
        connectivity: ConnectivityStatus.offline,
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('muestra spinner cuando sincronizando', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true, isDownloading: true),
        connectivity: ConnectivityStatus.online,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra icono cloud_off rojo cuando hay errores',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(
          isConnected: true,
          errors: ['Error de sync'],
        ),
        connectivity: ConnectivityStatus.online,
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('muestra label cuando showLabel es true', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
        showLabel: true,
      ));

      expect(find.text('Sincronizado'), findsOneWidget);
    });

    testWidgets('muestra label Sin conexión cuando offline', (tester) async {
      await tester.pumpWidget(createTestWidget(
        connectivity: ConnectivityStatus.offline,
        showLabel: true,
      ));

      expect(find.text('Sin conexión'), findsOneWidget);
    });

    testWidgets('tap abre bottom sheet con detalles', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
        interactive: true,
      ));

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Estado de Sincronización'), findsOneWidget);
    });

    testWidgets('bottom sheet muestra estado de conexión', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
        interactive: true,
      ));

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Conexión'), findsOneWidget);
      // "Conectado" aparece 2 veces: para WiFi y PowerSync
      expect(find.text('Conectado'), findsWidgets);
    });

    testWidgets('bottom sheet muestra errores si existen', (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(
          isConnected: true,
          errors: ['Error de prueba'],
        ),
        connectivity: ConnectivityStatus.online,
        interactive: true,
      ));

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Errores recientes'), findsOneWidget);
      expect(find.textContaining('Error de prueba'), findsOneWidget);
    });

    testWidgets('bottom sheet tiene botón sincronizar cuando online',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
        interactive: true,
      ));

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Sincronizar ahora'), findsOneWidget);
    });

    testWidgets('no abre bottom sheet cuando interactive es false',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        syncState: const SyncState(isConnected: true),
        connectivity: ConnectivityStatus.online,
        interactive: false,
      ));

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Estado de Sincronización'), findsNothing);
    });
  });
}

/// Mock del SyncStatus para tests
class _MockSyncStatus extends SyncStatus {
  final SyncState _state;

  _MockSyncStatus(this._state);

  @override
  SyncState build() => _state;
}

/// Mock del ConnectivityNotifier para tests
class _MockConnectivityNotifier extends ConnectivityNotifier {
  final ConnectivityStatus _status;

  _MockConnectivityNotifier(this._status);

  @override
  ConnectivityStatus build() => _status;
}
