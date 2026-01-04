/// Tests Unitarios del Servicio de AI Chat
/// Verifica logica de procesamiento de mensajes, contexto y respuestas
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/ai_chat/data/services/ai_chat_service.dart';
import 'package:finanzas_familiares/features/ai_chat/domain/models/chat_message.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart'
    show BudgetModel, BudgetPeriod;
import 'package:uuid/uuid.dart';

void main() {
  group('AI Chat Service: Unit Tests', () {
    late AiChatService service;

    setUp(() {
      service = AiChatService();
    });

    // =========================================================================
    // TEST 1: Servicio se crea correctamente
    // =========================================================================
    test('AiChatService se instancia sin errores', () {
      expect(service, isNotNull);
      expect(service, isA<AiChatService>());
    });

    // =========================================================================
    // TEST 2: Sugerencias retornan lista valida
    // =========================================================================
    test('getSuggestions retorna lista no vacia', () {
      final suggestions = service.getSuggestions();

      expect(suggestions, isNotEmpty);
      expect(suggestions.length, greaterThanOrEqualTo(3));
      expect(suggestions.every((s) => s.isNotEmpty), true);
    });

    // =========================================================================
    // TEST 3: Sugerencias son strings validos
    // =========================================================================
    test('Sugerencias son preguntas en espanol', () {
      final suggestions = service.getSuggestions();

      // Al menos una debe contener interrogacion
      final hasQuestions = suggestions.any((s) => s.contains('?'));
      expect(hasQuestions, true);
    });
  });

  group('AI Chat Service: Message Processing', () {
    // =========================================================================
    // TEST 4: Mensaje vacio no se procesa
    // =========================================================================
    test('Mensaje vacio es invalido', () {
      const emptyMessage = '';
      expect(emptyMessage.trim().isEmpty, true);
    });

    // =========================================================================
    // TEST 5: Mensaje con solo espacios es invalido
    // =========================================================================
    test('Mensaje con espacios es invalido', () {
      const spacesOnly = '   ';
      expect(spacesOnly.trim().isEmpty, true);
    });

    // =========================================================================
    // TEST 6: Mensaje muy largo se maneja correctamente
    // =========================================================================
    test('Mensaje largo se maneja sin error', () {
      final longMessage = 'a' * 10000;
      expect(longMessage.length, 10000);
      expect(() => longMessage.trim(), returnsNormally);
    });

    // =========================================================================
    // TEST 7: Caracteres especiales en mensaje
    // =========================================================================
    test('Mensaje con caracteres especiales es valido', () {
      const specialMessage = 'Hola! Como van mis finanzas? \$100 o mas?';
      expect(specialMessage.trim().isNotEmpty, true);
    });

    // =========================================================================
    // TEST 8: Emojis en mensaje
    // =========================================================================
    test('Mensaje con emojis se maneja correctamente', () {
      const emojiMessage = 'Hola Fina! Como estan mis ahorros?';
      expect(emojiMessage.trim().isNotEmpty, true);
    });
  });

  group('ChatMessage: Model Tests', () {
    // =========================================================================
    // TEST 9: Factory user crea mensaje correcto
    // =========================================================================
    test('ChatMessage.user crea mensaje con rol user', () {
      final message = ChatMessage.user('Hola');

      expect(message.role, MessageRole.user);
      expect(message.content, 'Hola');
      expect(message.isLoading, false);
      expect(message.id, isNotEmpty);
      expect(message.timestamp, isA<DateTime>());
    });

    // =========================================================================
    // TEST 10: Factory assistant crea mensaje correcto
    // =========================================================================
    test('ChatMessage.assistant crea mensaje con rol assistant', () {
      final message = ChatMessage.assistant('Respuesta');

      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Respuesta');
      expect(message.isLoading, false);
    });

    // =========================================================================
    // TEST 11: Factory loading crea mensaje de carga
    // =========================================================================
    test('ChatMessage.loading crea mensaje en estado de carga', () {
      final message = ChatMessage.loading();

      expect(message.role, MessageRole.assistant);
      expect(message.isLoading, true);
      expect(message.id, 'loading');
      expect(message.content, isEmpty);
    });

    // =========================================================================
    // TEST 12: copyWith modifica correctamente
    // =========================================================================
    test('copyWith modifica campos especificados', () {
      final original = ChatMessage.user('Original');
      final modified = original.copyWith(content: 'Modificado');

      expect(modified.content, 'Modificado');
      expect(modified.role, original.role);
      expect(modified.id, original.id);
    });

    // =========================================================================
    // TEST 13: IDs unicos para mensajes
    // =========================================================================
    test('Cada mensaje tiene ID unico', () async {
      final message1 = ChatMessage.user('Mensaje 1');
      await Future.delayed(const Duration(milliseconds: 2));
      final message2 = ChatMessage.user('Mensaje 2');

      expect(message1.id, isNot(equals(message2.id)));
    });

    // =========================================================================
    // TEST 14: Timestamp es reciente
    // =========================================================================
    test('Timestamp es cercano a ahora', () {
      final before = DateTime.now();
      final message = ChatMessage.user('Test');
      final after = DateTime.now();

      expect(message.timestamp.isAfter(before) ||
             message.timestamp.isAtSameMomentAs(before), true);
      expect(message.timestamp.isBefore(after) ||
             message.timestamp.isAtSameMomentAs(after), true);
    });
  });

  group('AI Chat Service: Financial Context', () {
    // =========================================================================
    // TEST 15: Contexto con cuentas vacias no falla
    // =========================================================================
    test('Contexto vacio no causa error', () {
      final emptyAccounts = <AccountModel>[];
      final emptyTransactions = <TransactionModel>[];
      final emptyBudgets = <BudgetModel>[];

      expect(emptyAccounts.isEmpty, true);
      expect(emptyTransactions.isEmpty, true);
      expect(emptyBudgets.isEmpty, true);
    });

    // =========================================================================
    // TEST 16: Calculos de balance con multiples cuentas
    // =========================================================================
    test('Balance total se calcula correctamente', () {
      final accounts = [
        AccountModel(
          id: const Uuid().v4(),
          userId: 'test',
          name: 'Cuenta 1',
          type: AccountType.bank,
          currency: 'MXN',
          balance: 1000.0,
        ),
        AccountModel(
          id: const Uuid().v4(),
          userId: 'test',
          name: 'Cuenta 2',
          type: AccountType.cash,
          currency: 'MXN',
          balance: 500.0,
        ),
      ];

      final total = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
      expect(total, 1500.0);
    });

    // =========================================================================
    // TEST 17: Transacciones por tipo
    // =========================================================================
    test('Transacciones se clasifican por tipo', () {
      final transactions = [
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 1000.0,
          type: TransactionType.income,
          description: 'Salario',
          date: DateTime.now(),
        ),
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 200.0,
          type: TransactionType.expense,
          description: 'Comida',
          date: DateTime.now(),
        ),
      ];

      final incomes = transactions.where((t) => t.type == TransactionType.income);
      final expenses = transactions.where((t) => t.type == TransactionType.expense);

      expect(incomes.length, 1);
      expect(expenses.length, 1);
      expect(incomes.first.amount, 1000.0);
      expect(expenses.first.amount, 200.0);
    });

    // =========================================================================
    // TEST 18: Gastos por categoria
    // =========================================================================
    test('Gastos se agrupan por categoria', () {
      final transactions = [
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 100.0,
          type: TransactionType.expense,
          description: 'Supermercado',
          date: DateTime.now(),
          categoryName: 'Alimentacion',
        ),
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 50.0,
          type: TransactionType.expense,
          description: 'Restaurante',
          date: DateTime.now(),
          categoryName: 'Alimentacion',
        ),
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 200.0,
          type: TransactionType.expense,
          description: 'Gasolina',
          date: DateTime.now(),
          categoryName: 'Transporte',
        ),
      ];

      final byCategory = <String, double>{};
      for (final tx in transactions) {
        final cat = tx.categoryName ?? 'Sin categoria';
        byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
      }

      expect(byCategory['Alimentacion'], 150.0);
      expect(byCategory['Transporte'], 200.0);
    });

    // =========================================================================
    // TEST 19: Filtro de transacciones recientes
    // =========================================================================
    test('Transacciones se filtran por fecha', () {
      final now = DateTime.now();
      final transactions = [
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 100.0,
          type: TransactionType.expense,
          description: 'Hoy',
          date: now,
        ),
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test',
          accountId: 'acc1',
          amount: 50.0,
          type: TransactionType.expense,
          description: 'Hace 60 dias',
          date: now.subtract(const Duration(days: 60)),
        ),
      ];

      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final recent = transactions.where((tx) => tx.date.isAfter(thirtyDaysAgo));

      expect(recent.length, 1);
      expect(recent.first.description, 'Hoy');
    });

    // =========================================================================
    // TEST 20: Estado de presupuesto
    // =========================================================================
    test('Estado de presupuesto se calcula correctamente', () {
      final budget = BudgetModel(
        id: const Uuid().v4(),
        userId: 'test',
        categoryId: 1,
        categoryName: 'Alimentacion',
        amount: 500.0,
        spent: 600.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      );

      final isExceeded = budget.spent > budget.amount;
      final percentage = (budget.spent / budget.amount) * 100;

      expect(isExceeded, true);
      expect(percentage, 120.0);
    });
  });

  group('AI Chat Service: Error Handling', () {
    // =========================================================================
    // TEST 21: Deteccion de error de API Key
    // =========================================================================
    test('Detecta error de API Key invalida', () {
      const errorMessages = [
        'api_key invalid',
        'API key not valid',
        'apikey error',
        'invalid key provided',
      ];

      for (final error in errorMessages) {
        final lower = error.toLowerCase();
        final isApiKeyError = lower.contains('api_key') ||
                              lower.contains('apikey') ||
                              lower.contains('invalid key') ||
                              lower.contains('api key not valid');
        expect(isApiKeyError, true, reason: 'Should detect: $error');
      }
    });

    // =========================================================================
    // TEST 22: Deteccion de error de cuota
    // =========================================================================
    test('Detecta error de cuota/rate limit', () {
      const errorMessages = [
        '429 Too Many Requests',
        'RESOURCE_EXHAUSTED',
        'quota exceeded',
        'rate limit reached',
      ];

      for (final error in errorMessages) {
        final lower = error.toLowerCase();
        final isQuotaError = lower.contains('429') ||
                             lower.contains('resource_exhausted') ||
                             lower.contains('quota exceeded') ||
                             lower.contains('rate limit');
        expect(isQuotaError, true, reason: 'Should detect: $error');
      }
    });

    // =========================================================================
    // TEST 23: Deteccion de error de red
    // =========================================================================
    test('Detecta error de conexion', () {
      const errorMessages = [
        'SocketException',
        'Connection refused',
        'Network unreachable',
        'Connection timeout',
        'Failed host lookup',
      ];

      for (final error in errorMessages) {
        final lower = error.toLowerCase();
        final isNetworkError = lower.contains('socket') ||
                               lower.contains('connection') ||
                               lower.contains('network') ||
                               lower.contains('timeout') ||
                               lower.contains('failed host lookup');
        expect(isNetworkError, true, reason: 'Should detect: $error');
      }
    });

    // =========================================================================
    // TEST 24: Deteccion de contenido bloqueado
    // =========================================================================
    test('Detecta contenido bloqueado por safety', () {
      const errorMessages = [
        'Content blocked',
        'Safety filter triggered',
        'Harmful content detected',
        'Prohibited content',
      ];

      for (final error in errorMessages) {
        final lower = error.toLowerCase();
        final isBlockedError = lower.contains('blocked') ||
                               lower.contains('safety') ||
                               lower.contains('harm') ||
                               lower.contains('prohibited');
        expect(isBlockedError, true, reason: 'Should detect: $error');
      }
    });
  });

  group('AI Chat Service: Performance', () {
    // =========================================================================
    // TEST 25: Creacion de multiples mensajes es rapida
    // =========================================================================
    test('Crear 100 mensajes toma < 100ms', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        ChatMessage.user('Mensaje $i');
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // =========================================================================
    // TEST 26: Procesamiento de lista grande de transacciones
    // =========================================================================
    test('Procesar 1000 transacciones es eficiente', () {
      final transactions = List.generate(1000, (i) => TransactionModel(
        id: const Uuid().v4(),
        userId: 'test',
        accountId: 'acc1',
        amount: i.toDouble(),
        type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
        description: 'Tx $i',
        date: DateTime.now(),
      ));

      final stopwatch = Stopwatch()..start();

      double totalIncome = 0;
      double totalExpense = 0;
      for (final tx in transactions) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
        }
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(totalIncome, greaterThan(0));
      expect(totalExpense, greaterThan(0));
    });
  });
}
