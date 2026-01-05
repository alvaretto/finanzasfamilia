import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_provider_interface.dart';

/// Proveedor Gemini - Fallback gratuito con rate limiting
/// Máximo 10 mensajes por hora sin API key personal
class GeminiProvider implements AiProviderInterface {
  GenerativeModel? _model;
  String _modelName = 'gemini-2.0-flash-001';
  bool _isInitialized = false;
  String? _customApiKey;

  // Rate limiting para fallback
  static const _maxMessagesPerHour = 10;
  static const _storageKey = 'gemini_rate_limit';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  String get providerName => 'Google Gemini';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(String apiKey, {String? model}) async {
    _customApiKey = apiKey.isNotEmpty ? apiKey : null;
    final key = _customApiKey ?? dotenv.env['GEMINI_API_KEY'];

    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY no configurada');
    }

    if (model != null) _modelName = model;

    _model = GenerativeModel(
      model: _modelName,
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
    _isInitialized = true;
  }

  @override
  Future<String> sendMessage({
    required String message,
    required String systemPrompt,
    List<Map<String, String>>? history,
  }) async {
    if (!_isInitialized) {
      await initialize('');
    }

    // Verificar rate limit si usa API key del .env (fallback)
    final usingFallback = _customApiKey == null;
    if (usingFallback) {
      final canProceed = await _checkRateLimit();
      if (!canProceed) {
        return 'Has alcanzado el límite de mensajes gratuitos (10/hora). '
               'Configura tu propia API key en Ajustes → Configuración de IA '
               'para uso ilimitado.';
      }
    }

    try {
      final chat = _model!.startChat(history: []);

      final fullPrompt = '$systemPrompt\n\nUsuario: $message';
      final response = await chat.sendMessage(Content.text(fullPrompt));

      if (usingFallback) {
        await _recordUsage();
      }

      return response.text ?? 'No pude generar una respuesta.';
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized) {
        await initialize('');
      }
      final chat = _model!.startChat();
      await chat.sendMessage(Content.text('Hola'));
      return true;
    } catch (e) {
      debugPrint('Gemini test failed: $e');
      return false;
    }
  }

  Future<bool> _checkRateLimit() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data == null) return true;

      final timestamps = data.split(',')
          .map((s) => int.tryParse(s) ?? 0)
          .where((t) => t > 0)
          .toList();

      final hourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      final recentCount = timestamps.where((t) => t > hourAgo).length;

      return recentCount < _maxMessagesPerHour;
    } catch (e) {
      return true;
    }
  }

  Future<void> _recordUsage() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = await _storage.read(key: _storageKey);

      List<int> timestamps = [];
      if (data != null) {
        timestamps = data.split(',')
            .map((s) => int.tryParse(s) ?? 0)
            .where((t) => t > 0)
            .toList();
      }

      // Limpiar timestamps viejos (más de 1 hora)
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      timestamps = timestamps.where((t) => t > hourAgo).toList();
      timestamps.add(now);

      await _storage.write(key: _storageKey, value: timestamps.join(','));
    } catch (e) {
      debugPrint('Error recording rate limit: $e');
    }
  }

  String _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('api_key') || errorStr.contains('invalid key')) {
      return 'Error: API key de Gemini inválida.';
    }
    if (errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return 'Límite de uso alcanzado. Intenta en unos minutos.';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Sin conexión a internet.';
    }

    return 'Error: ${e.toString()}';
  }
}
