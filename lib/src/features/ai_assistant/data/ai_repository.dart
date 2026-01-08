import 'package:flutter/foundation.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/chat_message.dart';
import '../domain/financial_context.dart';

class AIRepository {
  /// Envía un mensaje al asistente IA
  Future<String> sendMessage({
    required String message,
    required FinancialContext context,
    List<ChatMessage> conversationHistory = const [],
  }) async {
    try {
      final client = SupabaseClientProvider.client;

      // Preparar historial de conversación (solo últimos 10 mensajes)
      final history = conversationHistory
          .take(10)
          .map((m) => m.toJson())
          .toList();

      // Llamar a la Edge Function
      final response = await client.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'financial_context': context.toJson(),
          'conversation_history': history,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Error desconocido';
        throw AIException('Error del servidor: $error');
      }

      final responseText = response.data['response'] as String?;
      if (responseText == null || responseText.isEmpty) {
        throw AIException('Respuesta vacía del asistente');
      }

      if (kDebugMode) {
        final usage = response.data['usage'];
        print('[AI] Tokens: input=${usage?['input_tokens']}, output=${usage?['output_tokens']}');
      }

      return responseText;
    } on AIException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[AI] Error: $e');
      }
      throw AIException('No se pudo conectar con el asistente: $e');
    }
  }

  /// Genera respuestas demo cuando no hay conexión o para testing
  String getDemoResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('mercado') || lower.contains('alimentación') || lower.contains('comida')) {
      return '''En este mes gastaste **\$1,200,000** en Alimentación:

| Categoría | Monto |
|-----------|-------|
| 🛒 Mercado | \$800,000 |
| 🍴 Restaurantes | \$300,000 |
| 🛵 Domicilios | \$100,000 |

**Desglose del Mercado:**
- Cárnicos: \$280,000 (35%)
- Frutas y Verduras: \$200,000 (25%)
- Lácteos: \$150,000 (19%)
- Otros: \$170,000 (21%)

💡 **Tip:** Tus gastos en restaurantes aumentaron 15% respecto al mes pasado. Considera preparar más comidas en casa para ahorrar.''';
    }

    if (lower.contains('ahorro') || lower.contains('ahorrar') || lower.contains('guardar')) {
      return '''Basado en tus finanzas actuales, aquí hay algunas sugerencias:

### 🎯 Oportunidades de Ahorro

1. **Reducir domicilios** - \$100,000/mes
   - 8 pedidos este mes → meta: máximo 4

2. **Optimizar servicios** - \$50,000/mes
   - Revisar plan de internet
   - Apagar luces innecesarias

3. **Mecato y snacks** - \$45,000/mes
   - Comprar en promociones

### 📈 Meta Sugerida
Podrías ahorrar hasta **\$200,000/mes** implementando estos cambios.

¿Quieres que profundice en alguna de estas áreas?''';
    }

    if (lower.contains('balance') || lower.contains('saldo') || lower.contains('tengo')) {
      return '''### 💰 Tu Balance Actual

**Saldo Total: \$1,400,000 COP**

| Lo que Tengo | Monto |
|--------------|-------|
| 💳 Nequi | \$450,000 |
| 🏦 Bancolombia | \$830,000 |
| 💵 Efectivo | \$120,000 |

**Este mes:**
- ✅ Ingresos: \$5,200,000
- ❌ Gastos: \$3,800,000
- 📊 Balance: +\$1,400,000

Estás en buena posición. Tu tasa de ahorro es del **27%**, ¡excelente!''';
    }

    if (lower.contains('gasto') || lower.contains('gasté') || lower.contains('gastos')) {
      return '''### 📊 Resumen de Gastos del Mes

**Total: \$3,800,000 COP**

| Categoría | Monto | % |
|-----------|-------|---|
| 🍽️ Alimentación | \$1,200,000 | 32% |
| 🚗 Transporte | \$450,000 | 12% |
| 💡 Servicios | \$380,000 | 10% |
| 🎬 Entretenimiento | \$250,000 | 7% |
| 📦 Otros | \$1,520,000 | 40% |

💡 **Observación:** La categoría "Otros" es muy alta. Te recomiendo revisar esas transacciones y categorizarlas mejor para un análisis más preciso.''';
    }

    return '''Entiendo tu pregunta sobre "$query".

Para darte una respuesta más precisa, puedo ayudarte con:

- 📊 **Análisis de gastos**: "¿Cuánto gasté en mercado?"
- 💰 **Balance actual**: "¿Cuál es mi saldo?"
- 💡 **Consejos de ahorro**: "¿Cómo puedo ahorrar más?"
- 📈 **Comparaciones**: "¿Gasté más este mes?"

¿Qué te gustaría explorar?''';
  }
}

class AIException implements Exception {
  final String message;
  AIException(this.message);

  @override
  String toString() => message;
}
