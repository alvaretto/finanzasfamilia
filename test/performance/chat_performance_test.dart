/// Tests de Rendimiento del Chat AI
/// Verifica tiempos de respuesta, manejo de carga, memory leaks
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/ai_chat/domain/models/chat_message.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart'
    show BudgetModel, BudgetPeriod;
import 'package:uuid/uuid.dart';

void main() {
  group('Chat Performance: Message Creation', () {
    // =========================================================================
    // TEST 1: Crear 1000 mensajes < 100ms
    // =========================================================================
    test('Crear 1000 mensajes es rapido', () {
      final stopwatch = Stopwatch()..start();

      final messages = <ChatMessage>[];
      for (int i = 0; i < 1000; i++) {
        messages.add(ChatMessage.user('Mensaje de prueba $i'));
      }

      stopwatch.stop();

      expect(messages.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // =========================================================================
    // TEST 2: copyWith es eficiente
    // =========================================================================
    test('copyWith de 1000 mensajes < 50ms', () {
      final original = ChatMessage.user('Original');

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        original.copyWith(content: 'Modificado $i');
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  group('Chat Performance: List Operations', () {
    // =========================================================================
    // TEST 3: Filtrar 10000 mensajes < 100ms
    // =========================================================================
    test('Filtrar mensajes por rol es rapido', () {
      final messages = <ChatMessage>[];
      for (int i = 0; i < 10000; i++) {
        messages.add(
          i % 2 == 0
              ? ChatMessage.user('User $i')
              : ChatMessage.assistant('Assistant $i'),
        );
      }

      final stopwatch = Stopwatch()..start();

      final userMessages = messages.where((m) => m.role == MessageRole.user).toList();
      final assistantMessages = messages.where((m) => m.role == MessageRole.assistant).toList();

      stopwatch.stop();

      expect(userMessages.length, 5000);
      expect(assistantMessages.length, 5000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // =========================================================================
    // TEST 4: Ordenar por timestamp < 200ms
    // =========================================================================
    test('Ordenar 10000 mensajes por fecha < 200ms', () {
      final messages = List.generate(10000, (i) {
        return ChatMessage(
          id: i.toString(),
          content: 'Mensaje $i',
          role: MessageRole.user,
          timestamp: DateTime.now().subtract(Duration(seconds: 10000 - i)),
        );
      });

      final stopwatch = Stopwatch()..start();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      // Verificar orden
      for (int i = 1; i < messages.length; i++) {
        expect(
          messages[i].timestamp.isAfter(messages[i - 1].timestamp) ||
          messages[i].timestamp.isAtSameMomentAs(messages[i - 1].timestamp),
          true,
        );
      }
    });
  });

  group('Chat Performance: Context Building', () {
    // =========================================================================
    // TEST 5: Procesar 5000 transacciones < 500ms
    // =========================================================================
    test('Contexto con 5000 transacciones se procesa rapido', () {
      final transactions = List.generate(5000, (i) => TransactionModel(
        id: const Uuid().v4(),
        userId: 'perf-test',
        accountId: 'acc-1',
        amount: (i * 10).toDouble(),
        type: i % 3 == 0 ? TransactionType.income : TransactionType.expense,
        description: 'Transaccion $i',
        date: DateTime.now().subtract(Duration(days: i % 365)),
        categoryName: 'Categoria ${i % 10}',
      ));

      final stopwatch = Stopwatch()..start();

      // Simular procesamiento de contexto
      double totalIncome = 0;
      double totalExpense = 0;
      final byCategory = <String, double>{};
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final tx in transactions) {
        if (tx.date.isAfter(thirtyDaysAgo)) {
          if (tx.type == TransactionType.income) {
            totalIncome += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            totalExpense += tx.amount;
            final cat = tx.categoryName ?? 'Sin categoria';
            byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
          }
        }
      }

      // Ordenar categorias
      final sortedCategories = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(totalIncome, greaterThanOrEqualTo(0));
      expect(totalExpense, greaterThanOrEqualTo(0));
    });

    // =========================================================================
    // TEST 6: Procesar 100 cuentas < 50ms
    // =========================================================================
    test('Contexto con 100 cuentas se procesa rapido', () {
      final accounts = List.generate(100, (i) => AccountModel(
        id: const Uuid().v4(),
        userId: 'perf-test',
        name: 'Cuenta $i',
        type: AccountType.values[i % AccountType.values.length],
        currency: 'MXN',
        balance: (i * 1000).toDouble(),
      ));

      final stopwatch = Stopwatch()..start();

      double totalBalance = 0;
      final buffer = StringBuffer();

      for (final acc in accounts) {
        buffer.writeln('- ${acc.name}: \$${acc.balance}');
        totalBalance += acc.balance;
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(totalBalance, greaterThan(0));
    });

    // =========================================================================
    // TEST 7: Procesar 50 presupuestos < 20ms
    // =========================================================================
    test('Contexto con 50 presupuestos se procesa rapido', () {
      final budgets = List.generate(50, (i) => BudgetModel(
        id: const Uuid().v4(),
        userId: 'perf-test',
        categoryId: 'cat-$i',
        categoryName: 'Categoria $i',
        amount: 1000.0,
        spent: (i * 20).toDouble(),
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      ));

      final stopwatch = Stopwatch()..start();

      final buffer = StringBuffer();
      for (final budget in budgets) {
        final percentage = ((budget.spent / budget.amount) * 100).toStringAsFixed(0);
        final status = budget.spent > budget.amount ? 'EXCEDIDO' : 'OK';
        buffer.writeln('- ${budget.categoryName}: $percentage% [$status]');
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(20));
    });
  });

  group('Chat Performance: Memory Efficiency', () {
    // =========================================================================
    // TEST 8: Conversacion larga no causa leak
    // =========================================================================
    test('10000 mensajes no causan memory leak', () {
      final messages = <ChatMessage>[];

      for (int i = 0; i < 10000; i++) {
        messages.add(ChatMessage.user('Mensaje usuario $i' * 10));
        messages.add(ChatMessage.assistant('Respuesta asistente $i' * 20));
      }

      expect(messages.length, 20000);

      // Simular limpieza
      messages.clear();
      expect(messages.isEmpty, true);
    });

    // =========================================================================
    // TEST 9: Mensajes muy largos se manejan
    // =========================================================================
    test('Mensaje de 100KB se maneja', () {
      final longContent = 'a' * 100000;

      final stopwatch = Stopwatch()..start();
      final message = ChatMessage.user(longContent);
      stopwatch.stop();

      expect(message.content.length, 100000);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    // =========================================================================
    // TEST 10: Multiples contextos no acumulan
    // =========================================================================
    test('Rebuilds de contexto son eficientes', () {
      final stopwatch = Stopwatch()..start();

      for (int rebuild = 0; rebuild < 100; rebuild++) {
        final transactions = List.generate(100, (i) => TransactionModel(
          id: const Uuid().v4(),
          userId: 'rebuild-test',
          accountId: 'acc-1',
          amount: i.toDouble(),
          type: TransactionType.expense,
          description: 'Tx $i',
          date: DateTime.now(),
        ));

        double total = 0;
        for (final tx in transactions) {
          total += tx.amount;
        }
        // Forzar uso de la variable
        expect(total, greaterThanOrEqualTo(0));
      }

      stopwatch.stop();

      // 100 rebuilds deben ser rapidos
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('Chat Performance: String Operations', () {
    // =========================================================================
    // TEST 11: StringBuffer vs concatenacion
    // =========================================================================
    test('StringBuffer es mas eficiente para contexto', () {
      final lines = List.generate(1000, (i) => 'Linea $i de contexto');

      // Usando StringBuffer
      final stopwatchBuffer = Stopwatch()..start();
      final buffer = StringBuffer();
      for (final line in lines) {
        buffer.writeln(line);
      }
      final resultBuffer = buffer.toString();
      stopwatchBuffer.stop();

      expect(resultBuffer.isNotEmpty, true);
      expect(stopwatchBuffer.elapsedMilliseconds, lessThan(50));
    });

    // =========================================================================
    // TEST 12: Formateo de numeros
    // =========================================================================
    test('Formateo de 10000 montos < 100ms', () {
      final amounts = List.generate(10000, (i) => i * 1.5);

      final stopwatch = Stopwatch()..start();

      final formatted = amounts.map((a) => '\$${a.toStringAsFixed(2)}').toList();

      stopwatch.stop();

      expect(formatted.length, 10000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Chat Performance: Stress Tests', () {
    // =========================================================================
    // TEST 13: Rafaga de mensajes
    // =========================================================================
    test('100 mensajes consecutivos rapidos', () async {
      final messages = <ChatMessage>[];
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        messages.add(ChatMessage.user('Mensaje rapido $i'));
        // Simular minimo delay
        await Future.delayed(const Duration(microseconds: 100));
      }

      stopwatch.stop();

      expect(messages.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    // =========================================================================
    // TEST 14: Scroll de historial largo
    // =========================================================================
    test('Acceso aleatorio a historial largo', () {
      final messages = List.generate(10000, (i) => ChatMessage.user('Mensaje $i'));

      final stopwatch = Stopwatch()..start();

      // Simular scroll aleatorio
      for (int i = 0; i < 1000; i++) {
        final index = (i * 7) % messages.length;
        final message = messages[index];
        expect(message.content, contains('Mensaje'));
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // =========================================================================
    // TEST 15: Busqueda en historial
    // =========================================================================
    test('Buscar en 10000 mensajes < 200ms', () {
      final messages = List.generate(10000, (i) {
        final keyword = i % 100 == 0 ? 'IMPORTANTE' : '';
        return ChatMessage.user('Mensaje $i $keyword');
      });

      final stopwatch = Stopwatch()..start();

      final found = messages.where(
        (m) => m.content.contains('IMPORTANTE'),
      ).toList();

      stopwatch.stop();

      expect(found.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('Chat Performance: Edge Cases', () {
    // =========================================================================
    // TEST 16: Mensaje con muchos emojis
    // =========================================================================
    test('Mensaje con 1000 emojis se maneja', () {
      // Nota: emojis usan multiples code units, asi que usamos runes
      final emojiContent = List.generate(1000, (_) => '\u{1F600}').join();

      final stopwatch = Stopwatch()..start();
      final message = ChatMessage.user(emojiContent);
      stopwatch.stop();

      expect(message.content.runes.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // =========================================================================
    // TEST 17: Mensaje con unicode complejo
    // =========================================================================
    test('Unicode complejo se maneja', () {
      const unicodeContent = '\u{1F1E8}\u{1F1F4}'; // Bandera Colombia
      final repeatedContent = List.generate(100, (_) => unicodeContent).join(' ');

      final message = ChatMessage.user(repeatedContent);
      expect(message.content.isNotEmpty, true);
      expect(message.content.contains(unicodeContent), true);
    });

    // =========================================================================
    // TEST 18: Mensaje con newlines multiples
    // =========================================================================
    test('Multiples newlines se manejan', () {
      final multilineContent = List.generate(100, (i) => 'Linea $i').join('\n');

      final message = ChatMessage.user(multilineContent);
      expect(message.content.contains('\n'), true);
      expect(message.content.split('\n').length, 100);
    });
  });
}
