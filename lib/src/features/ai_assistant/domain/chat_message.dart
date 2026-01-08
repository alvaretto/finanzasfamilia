import 'package:uuid/uuid.dart';

enum MessageRole {
  user,
  assistant,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isError = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
    };
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(role: MessageRole.user, content: content);
  }

  factory ChatMessage.assistant(String content, {bool isError = false}) {
    return ChatMessage(
      role: MessageRole.assistant,
      content: content,
      isError: isError,
    );
  }

  factory ChatMessage.welcome() {
    return ChatMessage.assistant(
      '''¡Hola! Soy **Fina**, tu asistente financiero personal.

Puedo ayudarte con:
- 📊 Análisis de tus gastos
- 💡 Consejos de ahorro
- 📈 Comparaciones mensuales
- 🎯 Seguimiento de presupuesto

¿Qué te gustaría saber sobre tus finanzas?''',
    );
  }

  factory ChatMessage.error(String message) {
    return ChatMessage.assistant(
      '❌ $message',
      isError: true,
    );
  }

  factory ChatMessage.offline() {
    return ChatMessage.assistant(
      '''⚠️ **Sin conexión**

El asistente IA necesita conexión a internet para funcionar.

Por favor, verifica tu conexión e intenta nuevamente.''',
      isError: true,
    );
  }
}
