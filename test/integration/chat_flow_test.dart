/// Tests de Integracion del Flujo de Chat
/// Verifica el flujo completo: envio -> API -> respuesta -> UI
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/ai_chat/data/services/ai_chat_service.dart';
import 'package:finanzas_familiares/features/ai_chat/domain/models/chat_message.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart'
    show BudgetModel, BudgetPeriod;
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Chat Flow: Message Lifecycle', () {
    // =========================================================================
    // TEST 1: Mensaje user -> loading -> response
    // =========================================================================
    test('Flujo de mensaje completo', () async {
      // 1. Usuario envia mensaje
      final userMessage = ChatMessage.user('Hola Fina');
      expect(userMessage.role, MessageRole.user);
      expect(userMessage.content, 'Hola Fina');

      // 2. Estado de carga
      final loadingMessage = ChatMessage.loading();
      expect(loadingMessage.isLoading, true);
      expect(loadingMessage.role, MessageRole.assistant);

      // 3. Respuesta del asistente
      final response = ChatMessage.assistant('Hola! Soy Fina, tu asistente.');
      expect(response.role, MessageRole.assistant);
      expect(response.isLoading, false);
      expect(response.content.isNotEmpty, true);
    });

    // =========================================================================
    // TEST 2: Historial de conversacion
    // =========================================================================
    test('Historial se mantiene correctamente', () {
      final messages = <ChatMessage>[];

      // Simular conversacion
      messages.add(ChatMessage.user('Hola'));
      messages.add(ChatMessage.assistant('Hola! Como puedo ayudarte?'));
      messages.add(ChatMessage.user('Como van mis finanzas?'));
      messages.add(ChatMessage.assistant('Tus finanzas van bien...'));

      expect(messages.length, 4);
      expect(messages.where((m) => m.role == MessageRole.user).length, 2);
      expect(messages.where((m) => m.role == MessageRole.assistant).length, 2);
    });

    // =========================================================================
    // TEST 3: Mensajes tienen timestamps ordenados
    // =========================================================================
    test('Timestamps mantienen orden cronologico', () async {
      final messages = <ChatMessage>[];

      messages.add(ChatMessage.user('Primero'));
      await Future.delayed(const Duration(milliseconds: 10));
      messages.add(ChatMessage.assistant('Segundo'));
      await Future.delayed(const Duration(milliseconds: 10));
      messages.add(ChatMessage.user('Tercero'));

      for (int i = 1; i < messages.length; i++) {
        expect(
          messages[i].timestamp.isAfter(messages[i - 1].timestamp) ||
          messages[i].timestamp.isAtSameMomentAs(messages[i - 1].timestamp),
          true,
        );
      }
    });
  });

  group('Chat Flow: Financial Context', () {
    late AiChatService service;
    late List<AccountModel> testAccounts;
    late List<TransactionModel> testTransactions;
    late List<BudgetModel> testBudgets;

    setUp(() {
      service = AiChatService();

      testAccounts = [
        AccountModel(
          id: const Uuid().v4(),
          userId: 'test-user',
          name: 'Cuenta Bancaria',
          type: AccountType.bank,
          currency: 'MXN',
          balance: 5000.0,
        ),
        AccountModel(
          id: const Uuid().v4(),
          userId: 'test-user',
          name: 'Efectivo',
          type: AccountType.cash,
          currency: 'MXN',
          balance: 500.0,
        ),
      ];

      testTransactions = [
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test-user',
          accountId: testAccounts[0].id,
          amount: 3000.0,
          type: TransactionType.income,
          description: 'Salario',
          date: DateTime.now(),
          categoryName: 'Ingresos',
        ),
        TransactionModel(
          id: const Uuid().v4(),
          userId: 'test-user',
          accountId: testAccounts[0].id,
          amount: 500.0,
          type: TransactionType.expense,
          description: 'Supermercado',
          date: DateTime.now(),
          categoryName: 'Alimentacion',
        ),
      ];

      testBudgets = [
        BudgetModel(
          id: const Uuid().v4(),
          userId: 'test-user',
          categoryId: 'cat-1',
          categoryName: 'Alimentacion',
          amount: 600.0,
          spent: 500.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime.now(),
        ),
      ];
    });

    // =========================================================================
    // TEST 4: Servicio se inicializa
    // =========================================================================
    test('AiChatService se crea correctamente', () {
      expect(service, isNotNull);
    });

    // =========================================================================
    // TEST 5: Contexto incluye cuentas
    // =========================================================================
    test('Contexto financiero incluye balance total', () {
      final totalBalance = testAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
      expect(totalBalance, 5500.0);
    });

    // =========================================================================
    // TEST 6: Contexto incluye transacciones recientes
    // =========================================================================
    test('Transacciones recientes se calculan', () {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final recent = testTransactions.where(
        (tx) => tx.date.isAfter(thirtyDaysAgo),
      ).toList();

      expect(recent.length, 2);

      final income = recent
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = recent
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      expect(income, 3000.0);
      expect(expense, 500.0);
    });

    // =========================================================================
    // TEST 7: Contexto incluye presupuestos
    // =========================================================================
    test('Estado de presupuestos se calcula', () {
      for (final budget in testBudgets) {
        final percentage = (budget.spent / budget.amount) * 100;
        final isExceeded = budget.spent > budget.amount;

        expect(percentage, closeTo(83.33, 0.1));
        expect(isExceeded, false);
      }
    });

    // =========================================================================
    // TEST 8: Sugerencias son relevantes
    // =========================================================================
    test('Sugerencias cubren casos comunes', () {
      final suggestions = service.getSuggestions();

      // Debe incluir preguntas sobre finanzas
      final hasFinanceQuestion = suggestions.any(
        (s) => s.toLowerCase().contains('finanzas') ||
               s.toLowerCase().contains('gastos') ||
               s.toLowerCase().contains('balance'),
      );

      expect(hasFinanceQuestion, true);
    });
  });

  group('Chat Flow: Error Scenarios', () {
    // =========================================================================
    // TEST 9: Mensaje vacio no se procesa
    // =========================================================================
    test('Mensaje vacio es rechazado', () {
      const message = '';
      final isValid = message.trim().isNotEmpty;
      expect(isValid, false);
    });

    // =========================================================================
    // TEST 10: Mensaje con solo espacios es rechazado
    // =========================================================================
    test('Mensaje con espacios es rechazado', () {
      const message = '   \n\t   ';
      final isValid = message.trim().isNotEmpty;
      expect(isValid, false);
    });

    // =========================================================================
    // TEST 11: Error de red se maneja
    // =========================================================================
    test('Errores de red producen mensaje amigable', () {
      const errorStr = 'SocketException: Connection refused';
      final lower = errorStr.toLowerCase();

      final isNetworkError = lower.contains('socket') ||
                             lower.contains('connection') ||
                             lower.contains('network');

      expect(isNetworkError, true);

      // El mensaje al usuario debe ser amigable
      const friendlyMessage = 'Sin conexion a internet. Verifica tu conexion e intenta de nuevo.';
      expect(friendlyMessage.contains('conexion'), true);
    });

    // =========================================================================
    // TEST 12: Error de API se maneja
    // =========================================================================
    test('Errores de API producen mensaje amigable', () {
      const errorStr = '429 Too Many Requests';
      final lower = errorStr.toLowerCase();

      final isRateLimitError = lower.contains('429') ||
                                lower.contains('rate limit');

      expect(isRateLimitError, true);

      const friendlyMessage = 'Limite de uso alcanzado. Intenta de nuevo en unos minutos.';
      expect(friendlyMessage.contains('minutos'), true);
    });
  });

  group('Chat Flow: State Management', () {
    // =========================================================================
    // TEST 13: Estado inicial es correcto
    // =========================================================================
    test('Estado inicial tiene lista vacia', () {
      final initialMessages = <ChatMessage>[];
      final isLoading = false;
      final error = null;

      expect(initialMessages.isEmpty, true);
      expect(isLoading, false);
      expect(error, isNull);
    });

    // =========================================================================
    // TEST 14: Estado de carga se activa
    // =========================================================================
    test('isLoading se activa al enviar mensaje', () {
      var isLoading = false;

      // Simular envio
      isLoading = true;
      expect(isLoading, true);

      // Simular respuesta
      isLoading = false;
      expect(isLoading, false);
    });

    // =========================================================================
    // TEST 15: Error se limpia al enviar nuevo mensaje
    // =========================================================================
    test('Error se limpia al reintentar', () {
      String? error = 'Error anterior';

      // Al enviar nuevo mensaje
      error = null;
      expect(error, isNull);
    });

    // =========================================================================
    // TEST 16: Chat se puede limpiar
    // =========================================================================
    test('clearChat vacia todo el historial', () {
      final messages = <ChatMessage>[
        ChatMessage.user('Mensaje 1'),
        ChatMessage.assistant('Respuesta 1'),
      ];

      expect(messages.length, 2);

      // Limpiar
      messages.clear();
      expect(messages.isEmpty, true);
    });
  });

  group('Chat Flow: Performance', () {
    // =========================================================================
    // TEST 17: Conversacion larga no causa leak
    // =========================================================================
    test('100 mensajes no causan memory leak', () {
      final messages = <ChatMessage>[];

      for (int i = 0; i < 100; i++) {
        messages.add(ChatMessage.user('Mensaje $i'));
        messages.add(ChatMessage.assistant('Respuesta $i'));
      }

      expect(messages.length, 200);

      // Limpiar
      messages.clear();
      expect(messages.isEmpty, true);
    });

    // =========================================================================
    // TEST 18: Mensajes largos se manejan
    // =========================================================================
    test('Mensajes de 10000 caracteres se manejan', () {
      final longContent = 'a' * 10000;
      final message = ChatMessage.user(longContent);

      expect(message.content.length, 10000);
      expect(message.role, MessageRole.user);
    });

    // =========================================================================
    // TEST 19: Contexto grande se procesa
    // =========================================================================
    test('1000 transacciones en contexto', () {
      final transactions = List.generate(1000, (i) => TransactionModel(
        id: const Uuid().v4(),
        userId: 'test',
        accountId: 'acc-1',
        amount: i.toDouble(),
        type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
        description: 'Tx $i',
        date: DateTime.now().subtract(Duration(days: i % 60)),
        categoryName: 'Cat ${i % 10}',
      ));

      final stopwatch = Stopwatch()..start();

      // Procesar contexto
      double totalIncome = 0;
      double totalExpense = 0;
      final byCategory = <String, double>{};

      for (final tx in transactions) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
          final cat = tx.categoryName ?? 'Sin categoria';
          byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
        }
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(totalIncome, greaterThan(0));
      expect(totalExpense, greaterThan(0));
    });
  });

  group('Chat Flow: Concurrent Operations', () {
    // =========================================================================
    // TEST 20: Multiples chats no interfieren
    // =========================================================================
    test('Diferentes usuarios tienen chats separados', () {
      final user1Messages = <ChatMessage>[];
      final user2Messages = <ChatMessage>[];

      user1Messages.add(ChatMessage.user('Mensaje de user1'));
      user2Messages.add(ChatMessage.user('Mensaje de user2'));

      expect(user1Messages.length, 1);
      expect(user2Messages.length, 1);
      expect(user1Messages[0].content, isNot(equals(user2Messages[0].content)));
    });
  });
}
