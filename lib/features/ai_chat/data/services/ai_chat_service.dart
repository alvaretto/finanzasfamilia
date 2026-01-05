import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../transactions/domain/models/transaction_model.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../budgets/domain/models/budget_model.dart' show BudgetModel;

/// Servicio de chat con IA
class AiChatService {
  GenerativeModel? _model;

  /// Inicializar el modelo
  Future<void> initialize() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no configurada en .env');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
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
      buffer.writeln('- ${acc.name} (${acc.type.displayName}): \$${acc.balance.toStringAsFixed(2)} ${acc.currency}');
      totalBalance += acc.balance;
    }
    buffer.writeln('Balance total: \$${totalBalance.toStringAsFixed(2)}');
    buffer.writeln();

    // Resumen de transacciones recientes
    buffer.writeln('=== TRANSACCIONES RECIENTES (ultimos 30 dias) ===');
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
        final cat = tx.categoryName ?? 'Sin categoria';
        expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + tx.amount;
      }
    }

    buffer.writeln('Ingresos del mes: \$${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Gastos del mes: \$${totalExpense.toStringAsFixed(2)}');
    buffer.writeln('Balance del mes: \$${(totalIncome - totalExpense).toStringAsFixed(2)}');
    buffer.writeln();

    buffer.writeln('Gastos por categoria:');
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedCategories.take(5)) {
      final percentage = ((entry.value / totalExpense) * 100).toStringAsFixed(1);
      buffer.writeln('- ${entry.key}: \$${entry.value.toStringAsFixed(2)} ($percentage%)');
    }
    buffer.writeln();

    // Presupuestos
    buffer.writeln('=== PRESUPUESTOS ===');
    for (final budget in budgets) {
      final percentage = ((budget.spent / budget.amount) * 100).toStringAsFixed(0);
      final status = budget.spent > budget.amount ? 'EXCEDIDO' : 'OK';
      buffer.writeln('- ${budget.categoryName ?? "General"}: \$${budget.spent.toStringAsFixed(2)} / \$${budget.amount.toStringAsFixed(2)} ($percentage%) [$status]');
    }

    return buffer.toString();
  }

  /// Enviar mensaje y obtener respuesta
  Future<String> sendMessage({
    required String userMessage,
    required List<TransactionModel> transactions,
    required List<AccountModel> accounts,
    required List<BudgetModel> budgets,
    List<Content>? history,
  }) async {
    if (_model == null) {
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
1. Responde en espanol de manera clara y concisa
2. Usa los datos financieros del usuario para dar respuestas personalizadas
3. Cuando des consejos, se especifico basandote en sus numeros reales
4. Si el usuario pregunta algo que no puedes saber con los datos disponibles, dilo claramente
5. Usa formato amigable con emojis ocasionalmente para hacer la conversacion mas agradable
6. Si detectas problemas financieros (gastos excesivos, presupuestos excedidos), sugiere mejoras
7. Sé positivo pero honesto
8. Mantén las respuestas concisas (maximo 200 palabras a menos que el usuario pida detalles)
''';

    try {
      final chat = _model!.startChat(
        history: history ?? [],
      );

      final fullPrompt = history == null || history.isEmpty
          ? '$systemPrompt\n\nUsuario: $userMessage'
          : userMessage;

      final response = await chat.sendMessage(Content.text(fullPrompt));
      return response.text ?? 'No pude generar una respuesta.';
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      // Error de API Key
      if (errorStr.contains('api_key') || errorStr.contains('apikey') ||
          errorStr.contains('invalid key') || errorStr.contains('api key not valid')) {
        return 'Error de configuracion: La clave de API de Gemini no es valida. Contacta al desarrollador.';
      }

      // Error de cuota/limite (429 o RESOURCE_EXHAUSTED de Google)
      if (errorStr.contains('429') || errorStr.contains('resource_exhausted') ||
          errorStr.contains('quota exceeded') || errorStr.contains('rate limit')) {
        return 'Limite de uso alcanzado. Intenta de nuevo en unos minutos.';
      }

      // Error de red/conexion
      if (errorStr.contains('socket') || errorStr.contains('connection') ||
          errorStr.contains('network') || errorStr.contains('timeout') ||
          errorStr.contains('failed host lookup') || errorStr.contains('no address')) {
        return 'Sin conexion a internet. Verifica tu conexion e intenta de nuevo.';
      }

      // Error de contenido bloqueado
      if (errorStr.contains('blocked') || errorStr.contains('safety') ||
          errorStr.contains('harm') || errorStr.contains('prohibited')) {
        return 'No puedo responder a esa pregunta. Intenta reformularla.';
      }

      // Error generico con mas detalle
      // Mostrar error completo para debugging (remover en producción)
      return 'Error: ${e.toString()}';
    }
  }

  /// Sugerencias de preguntas
  List<String> getSuggestions() {
    return [
      '¿Como van mis finanzas este mes?',
      '¿En que estoy gastando mas?',
      '¿Estoy cumpliendo mis presupuestos?',
      'Dame consejos para ahorrar',
      '¿Cual es mi balance actual?',
      'Analiza mis gastos de la semana',
    ];
  }
}
