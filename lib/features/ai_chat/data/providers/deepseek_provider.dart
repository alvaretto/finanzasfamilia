import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_provider_interface.dart';

/// Proveedor DeepSeek - Muy económico y potente
/// Usa API compatible con OpenAI
class DeepSeekProvider implements AiProviderInterface {
  String? _apiKey;
  String _modelName = 'deepseek-chat';
  bool _isInitialized = false;

  static const _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  @override
  String get providerName => 'DeepSeek';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(String apiKey, {String? model}) async {
    if (apiKey.isEmpty) {
      throw Exception('API key de DeepSeek requerida');
    }

    _apiKey = apiKey;
    if (model != null) _modelName = model;
    _isInitialized = true;
  }

  @override
  Future<String> sendMessage({
    required String message,
    required String systemPrompt,
    List<Map<String, String>>? history,
  }) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('DeepSeek no inicializado. Configura tu API key.');
    }

    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      // Agregar historial si existe
      if (history != null) {
        for (final h in history) {
          messages.add({
            'role': h['role'] ?? 'user',
            'content': h['content'] ?? '',
          });
        }
      }

      // Agregar mensaje actual
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices.first['message']['content'] ?? 'Sin respuesta';
        }
        return 'Sin respuesta';
      } else {
        return _handleHttpError(response);
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized || _apiKey == null) return false;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': [{'role': 'user', 'content': 'Hola'}],
          'max_tokens': 10,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeepSeek test failed: $e');
      return false;
    }
  }

  String _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return 'Error: API key de DeepSeek inválida.';
      case 429:
        return 'Límite de uso alcanzado. Intenta en unos minutos.';
      case 500:
      case 502:
      case 503:
        return 'Servicio de DeepSeek temporalmente no disponible.';
      default:
        return 'Error ${response.statusCode}: ${response.body}';
    }
  }

  String _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Sin conexión a internet.';
    }

    return 'Error DeepSeek: ${e.toString()}';
  }
}
