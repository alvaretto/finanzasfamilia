import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/domain/models/transaction_model.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../budgets/domain/models/budget_model.dart' show BudgetModel;
import '../../presentation/providers/ai_settings_provider.dart';
import '../providers/ai_provider_interface.dart';

/// Servicio de chat con IA - Multi-proveedor
class AiChatService {
  final Ref _ref;
  AiProviderInterface? _provider;
  bool _isInitialized = false;

  AiChatService(this._ref);

  /// Inicializar el proveedor según configuración
  Future<void> initialize() async {
    final settings = _ref.read(aiSettingsProvider);
    _provider = _ref.read(aiProviderInstanceProvider);

    await _provider!.initialize(
      settings.apiKey ?? '',
      model: settings.currentModel,
    );
    _isInitialized = true;
  }

  /// Generar contexto financiero del usuario
  String _buildFinancialContext({
    required List<TransactionModel> transactions,
    required List<AccountModel> accounts,
    required List<BudgetModel> budgets,
  }) {
    final buffer = StringBuffer();

    // Resumen de cuentas
    buffer.writeln('=== CUENTAS DEL USUARIO ===');
    double totalBalance = 0;
    for (final acc in accounts) {
      buffer.writeln('- ${acc.name} (${acc.type.displayName}): \$${acc.balance.toStringAsFixed(0)} ${acc.currency}');
      totalBalance += acc.balance;
    }
    buffer.writeln('Balance total: \$${totalBalance.toStringAsFixed(0)}');
    buffer.writeln();

    // Resumen de transacciones recientes
    buffer.writeln('=== TRANSACCIONES RECIENTES (últimos 30 días) ===');
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentTx = transactions.where((tx) => tx.date.isAfter(thirtyDaysAgo)).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = {};

    for (final tx in recentTx) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        final cat = tx.categoryName ?? 'Sin categoría';
        expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + tx.amount;
      }
    }

    buffer.writeln('Ingresos del mes: \$${totalIncome.toStringAsFixed(0)}');
    buffer.writeln('Gastos del mes: \$${totalExpense.toStringAsFixed(0)}');
    buffer.writeln('Balance del mes: \$${(totalIncome - totalExpense).toStringAsFixed(0)}');
    buffer.writeln();

    buffer.writeln('Gastos por categoría:');
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedCategories.take(5)) {
      final percentage = totalExpense > 0
          ? ((entry.value / totalExpense) * 100).toStringAsFixed(1)
          : '0';
      buffer.writeln('- ${entry.key}: \$${entry.value.toStringAsFixed(0)} ($percentage%)');
    }
    buffer.writeln();

    // Presupuestos
    buffer.writeln('=== PRESUPUESTOS ===');
    for (final budget in budgets) {
      final percentage = budget.amount > 0
          ? ((budget.spent / budget.amount) * 100).toStringAsFixed(0)
          : '0';
      final status = budget.spent > budget.amount ? 'EXCEDIDO' : 'OK';
      buffer.writeln('- ${budget.categoryName ?? "General"}: \$${budget.spent.toStringAsFixed(0)} / \$${budget.amount.toStringAsFixed(0)} ($percentage%) [$status]');
    }

    return buffer.toString();
  }

  /// Enviar mensaje y obtener respuesta
  Future<String> sendMessage({
    required String userMessage,
    required List<TransactionModel> transactions,
    required List<AccountModel> accounts,
    required List<BudgetModel> budgets,
    List<Map<String, String>>? history,
  }) async {
    if (!_isInitialized || _provider == null) {
      await initialize();
    }

    final context = _buildFinancialContext(
      transactions: transactions,
      accounts: accounts,
      budgets: budgets,
    );

    final systemPrompt = '''
Eres un asistente financiero personal amigable y experto. Tu nombre es "Fina" (de Finanzas).
Ayudas a los usuarios a entender y mejorar sus finanzas personales y familiares.

CONTEXTO FINANCIERO ACTUAL DEL USUARIO:
$context

INSTRUCCIONES:
1. Responde en español de manera clara y concisa
2. Usa los datos financieros del usuario para dar respuestas personalizadas
3. Cuando des consejos, sé específico basándote en sus números reales
4. Si el usuario pregunta algo que no puedes saber con los datos disponibles, dilo claramente
5. Usa formato amigable con emojis ocasionalmente para hacer la conversación más agradable
6. Si detectas problemas financieros (gastos excesivos, presupuestos excedidos), sugiere mejoras
7. Sé positivo pero honesto
8. Mantén las respuestas concisas (máximo 200 palabras a menos que el usuario pida detalles)
''';

    return await _provider!.sendMessage(
      message: userMessage,
      systemPrompt: systemPrompt,
      history: history,
    );
  }

  /// Sugerencias de preguntas
  List<String> getSuggestions() {
    return [
      '¿Cómo van mis finanzas este mes?',
      '¿En qué estoy gastando más?',
      '¿Estoy cumpliendo mis presupuestos?',
      'Dame consejos para ahorrar',
      '¿Cuál es mi balance actual?',
      'Analiza mis gastos de la semana',
    ];
  }

  /// Obtener nombre del proveedor actual
  String get currentProviderName => _provider?.providerName ?? 'No configurado';
}

/// Provider del servicio de chat
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService(ref);
});
