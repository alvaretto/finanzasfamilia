import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/ai_chat/domain/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('user() crea mensaje de usuario', () {
      final message = ChatMessage.user('Hola, como van mis finanzas?');

      expect(message.content, 'Hola, como van mis finanzas?');
      expect(message.role, MessageRole.user);
      expect(message.isLoading, false);
      expect(message.id, isNotEmpty);
    });

    test('assistant() crea mensaje de asistente', () {
      final message = ChatMessage.assistant('Tus finanzas van bien!');

      expect(message.content, 'Tus finanzas van bien!');
      expect(message.role, MessageRole.assistant);
      expect(message.isLoading, false);
    });

    test('loading() crea mensaje de carga', () {
      final message = ChatMessage.loading();

      expect(message.content, '');
      expect(message.role, MessageRole.assistant);
      expect(message.isLoading, true);
      expect(message.id, 'loading');
    });

    test('copyWith modifica valores correctamente', () {
      final original = ChatMessage.user('Mensaje original');
      final modified = original.copyWith(content: 'Mensaje modificado');

      expect(original.content, 'Mensaje original');
      expect(modified.content, 'Mensaje modificado');
      expect(modified.role, MessageRole.user);
    });

    test('timestamp se genera automaticamente', () {
      final before = DateTime.now();
      final message = ChatMessage.user('Test');
      final after = DateTime.now();

      expect(message.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(message.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  group('MessageRole', () {
    test('tiene todos los roles necesarios', () {
      expect(MessageRole.values.length, 3);
      expect(MessageRole.values.contains(MessageRole.user), true);
      expect(MessageRole.values.contains(MessageRole.assistant), true);
      expect(MessageRole.values.contains(MessageRole.system), true);
    });
  });
}
