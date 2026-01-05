import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/domain/models/transaction_model.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../budgets/domain/models/budget_model.dart' show BudgetModel;
import '../../presentation/providers/ai_settings_provider.dart';
import '../../domain/models/ai_settings_model.dart';
import '../providers/ai_provider_interface.dart';

/// Servicio de chat con IA - Multi-proveedor
class AiChatService {
  final Ref _ref;
  AiProviderInterface? _provider;
  AiProvider? _lastProvider;
  String? _lastApiKey;

  AiChatService(this._ref);

  /// Verificar si necesita reinicializar (configuración cambió)
  bool _needsReinitialize(AiSettingsModel settings) {
    return _provider == null ||
        _lastProvider != settings.provider ||
        _lastApiKey != settings.apiKey;
  }

  /// Esperar a que los settings estén cargados
  Future<void> _waitForSettingsLoaded() async {
    final notifier = _ref.read(aiSettingsProvider.notifier);
    await notifier.initialized;
  }

  /// Inicializar el proveedor según configuración
  Future<void> _ensureInitialized() async {
    // IMPORTANTE: Esperar a que los settings estén cargados desde storage
    await _waitForSettingsLoaded();
    
    final settings = _ref.read(aiSettingsProvider);

    // Verificar que ya no esté cargando
    if (settings.isLoading) {
      throw Exception('Los ajustes de IA aún se están cargando');
    }

    // Solo reinicializar si cambió la configuración
    if (!_needsReinitialize(settings)) return;

    _provider = _ref.read(aiProviderInstanceProvider);
    _lastProvider = settings.provider;
    _lastApiKey = settings.apiKey;

    await _provider!.initialize(
      settings.apiKey ?? '',
      model: settings.currentModel,
    );
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
    // SIEMPRE esperar a que los settings estén cargados antes de inicializar
    await _ensureInitialized();

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

INSTRUCCIONES DE FORMATO (MUY IMPORTANTE):
- NUNCA uses formato Markdown (nada de asteriscos, guiones, numeraciones, headers)
- Responde en párrafos cortos y conversacionales
- Usa emojis con moderación para hacer el texto más amigable 💰📊
- Para listas, escribe de forma natural: "tienes gastos en comida, transporte y entretenimiento"
- Para énfasis, usa mayúsculas ocasionales en lugar de negritas
- Separa ideas con saltos de línea, no con viñetas

INSTRUCCIONES DE CONTENIDO:
1. Responde en español de manera clara y concisa
2. Usa los datos financieros del usuario para dar respuestas personalizadas
3. Cuando des consejos, sé específico basándote en sus números reales
4. Si el usuario pregunta algo que no puedes saber con los datos disponibles, dilo claramente
5. Si detectas problemas financieros (gastos excesivos, presupuestos excedidos), sugiere mejoras
6. Sé positivo pero honesto
7. Mantén las respuestas concisas (máximo 150 palabras a menos que el usuario pida detalles)
8. Habla como un amigo que sabe de finanzas, no como un documento formal
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
