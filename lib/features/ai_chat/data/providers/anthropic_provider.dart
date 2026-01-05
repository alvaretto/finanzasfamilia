import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_provider_interface.dart';

/// Proveedor Anthropic Claude - Premium
class AnthropicProvider implements AiProviderInterface {
  String? _apiKey;
  String _modelName = 'claude-sonnet-4-20250514';
  bool _isInitialized = false;

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  @override
  String get providerName => 'Anthropic Claude';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(String apiKey, {String? model}) async {
    if (apiKey.isEmpty) {
      throw Exception('API key de Anthropic requerida');
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
      throw Exception('Anthropic no inicializado. Configura tu API key.');
    }

    try {
      final messages = <Map<String, dynamic>>[];

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
      messages.add({
        'role': 'user',
        'content': message,
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': _modelName,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return content.first['text'] ?? 'Sin respuesta';
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
          'x-api-key': _apiKey!,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': _modelName,
          'max_tokens': 10,
          'messages': [{'role': 'user', 'content': 'Hola'}],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Anthropic test failed: $e');
      return false;
    }
  }

  String _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return 'Error: API key de Anthropic inválida.';
      case 429:
        return 'Límite de uso alcanzado. Intenta en unos minutos.';
      case 500:
      case 502:
      case 503:
        return 'Servicio de Anthropic temporalmente no disponible.';
      default:
        return 'Error ${response.statusCode}: ${response.body}';
    }
  }

  String _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Sin conexión a internet.';
    }

    return 'Error Anthropic: ${e.toString()}';
  }
}
