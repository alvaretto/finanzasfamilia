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

  static const _providerKey = 'ai_provider';
  static const _apiKeyKey = 'ai_api_key';
  static const _modelKey = 'ai_model';

  AiSettingsNotifier(this._storage) : super(const AiSettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final providerName = await _storage.read(key: _providerKey);
      final apiKey = await _storage.read(key: _apiKeyKey);
      final model = await _storage.read(key: _modelKey);

      final provider = AiProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => AiProvider.gemini,
      );

      state = AiSettingsModel(
        provider: provider,
        apiKey: apiKey,
        selectedModel: model,
        useCustomProvider: apiKey != null && apiKey.isNotEmpty,
      );
    } catch (e) {
      // Si hay error, usar configuración por defecto
      state = const AiSettingsModel();
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
