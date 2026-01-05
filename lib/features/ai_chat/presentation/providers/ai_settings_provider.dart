import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/ai_settings_model.dart';
import '../../data/providers/ai_provider_interface.dart';
import '../../data/providers/gemini_provider.dart';
import '../../data/providers/deepseek_provider.dart';
import '../../data/providers/anthropic_provider.dart';

/// Notifier para gestionar configuración de IA
class AiSettingsNotifier extends StateNotifier<AiSettingsModel> {
  final FlutterSecureStorage _storage;
  
  // Completer para indicar cuando la carga inicial está lista
  final Completer<void> _loadCompleter = Completer<void>();
  
  /// Future que se completa cuando los settings están cargados
  Future<void> get initialized => _loadCompleter.future;

  static const _providerKey = 'ai_provider';
  static const _apiKeyKey = 'ai_api_key';
  static const _modelKey = 'ai_model';

  AiSettingsNotifier(this._storage) : super(const AiSettingsModel(isLoading: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final providerName = await _storage.read(key: _providerKey);
      final apiKey = await _storage.read(key: _apiKeyKey);
      final model = await _storage.read(key: _modelKey);

      debugPrint('🔑 AI Settings loaded:');
      debugPrint('  Provider: $providerName');
      debugPrint('  API Key: ${apiKey != null ? "***${apiKey.substring(apiKey.length > 4 ? apiKey.length - 4 : 0)}" : "null"}');
      debugPrint('  Model: $model');

      final provider = AiProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => AiProvider.gemini,
      );

      state = AiSettingsModel(
        provider: provider,
        apiKey: apiKey,
        selectedModel: model,
        useCustomProvider: apiKey != null && apiKey.isNotEmpty,
        isLoading: false, // Ya terminó de cargar
      );
    } catch (e) {
      debugPrint('❌ Error loading AI settings: $e');
      // Si hay error, usar configuración por defecto pero marcar como cargado
      state = const AiSettingsModel(isLoading: false);
    } finally {
      // Completar el future para notificar que la carga terminó
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.complete();
      }
    }
  }

  Future<void> saveSettings(AiSettingsModel settings) async {
    await _storage.write(key: _providerKey, value: settings.provider.name);

    if (settings.apiKey != null && settings.apiKey!.isNotEmpty) {
      await _storage.write(key: _apiKeyKey, value: settings.apiKey);
    } else {
      await _storage.delete(key: _apiKeyKey);
    }

    if (settings.selectedModel != null) {
      await _storage.write(key: _modelKey, value: settings.selectedModel);
    }

    state = settings.copyWith(
      useCustomProvider: settings.apiKey != null && settings.apiKey!.isNotEmpty,
      isLoading: false,
    );
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _apiKeyKey);
    state = state.copyWith(
      apiKey: null,
      useCustomProvider: false,
    );
  }

  void setProvider(AiProvider provider) {
    state = state.copyWith(
      provider: provider,
      selectedModel: AiSettingsModel.availableModels[provider]?.first,
    );
  }

  void setModel(String model) {
    state = state.copyWith(selectedModel: model);
  }

  void setApiKey(String apiKey) {
    state = state.copyWith(apiKey: apiKey);
  }
}

/// Provider principal de configuración de IA
final aiSettingsProvider = StateNotifierProvider<AiSettingsNotifier, AiSettingsModel>((ref) {
  return AiSettingsNotifier(const FlutterSecureStorage());
});

/// Provider que expone el future de inicialización
final aiSettingsInitializedProvider = FutureProvider<void>((ref) async {
  final notifier = ref.read(aiSettingsProvider.notifier);
  await notifier.initialized;
});

/// Provider que crea la instancia correcta del proveedor de IA
final aiProviderInstanceProvider = Provider<AiProviderInterface>((ref) {
  final settings = ref.watch(aiSettingsProvider);

  switch (settings.provider) {
    case AiProvider.deepseek:
      return DeepSeekProvider();
    case AiProvider.anthropic:
      return AnthropicProvider();
    case AiProvider.gemini:
      return GeminiProvider();
  }
});
