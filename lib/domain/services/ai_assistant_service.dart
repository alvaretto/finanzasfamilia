import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/financial_context.dart';

/// Servicio para interactuar con el asistente IA "Fina"
/// Usa Supabase Edge Functions para mantener la API key segura
class AIAssistantService {
  final SupabaseClient _client;

  AIAssistantService(this._client);

  /// Envía un mensaje al asistente IA
  /// [message] La pregunta del usuario
  /// [context] El contexto financiero anónimo del usuario
  /// Returns la respuesta del asistente
  Future<String> sendMessage({
    required String message,
    required FinancialContext context,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'financial_context': context.toJson(),
          'conversation_history': conversationHistory
              ?.map((m) => {
                    'role': m.role.name,
                    'content': m.content,
                  })
              .toList(),
        },
      );

      if (response.status != 200) {
        throw AIAssistantException(
          'Error del servidor: ${response.status}',
          response.status,
        );
      }

      final data = response.data as Map<String, dynamic>;
      return data['response'] as String;
    } on FunctionException catch (e) {
      throw AIAssistantException(
        'Error al conectar con el asistente: ${e.details}',
        e.status,
      );
    } catch (e) {
      if (e is AIAssistantException) rethrow;
      throw AIAssistantException(
        'Error inesperado: $e',
        500,
      );
    }
  }

  /// Verifica si el servicio de IA está disponible
  Future<bool> isAvailable() async {
    try {
      final response = await _client.functions.invoke(
        'ai-chat',
        body: {
          'message': 'ping',
          'financial_context': {},
        },
      );
      return response.status == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Excepción personalizada para errores del asistente IA
class AIAssistantException implements Exception {
  final String message;
  final int statusCode;

  AIAssistantException(this.message, this.statusCode);

  @override
  String toString() => 'AIAssistantException: $message (status: $statusCode)';

  bool get isNetworkError => statusCode == 0 || statusCode >= 500;
  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isRateLimitError => statusCode == 429;
}
