/// Modelo de configuración del proveedor de IA
/// El usuario puede elegir su proveedor preferido y configurar su API key

enum AiProvider {
  gemini('Gemini', 'Gratuito con límites'),
  deepseek('DeepSeek', 'Muy económico'),
  anthropic('Claude', 'Premium');

  final String displayName;
  final String description;
  const AiProvider(this.displayName, this.description);
}

class AiSettingsModel {
  final AiProvider provider;
  final String? apiKey;
  final String? selectedModel;
  final bool useCustomProvider;

  const AiSettingsModel({
    this.provider = AiProvider.gemini,
    this.apiKey,
    this.selectedModel,
    this.useCustomProvider = false,
  });

  AiSettingsModel copyWith({
    AiProvider? provider,
    String? apiKey,
    String? selectedModel,
    bool? useCustomProvider,
  }) {
    return AiSettingsModel(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      useCustomProvider: useCustomProvider ?? this.useCustomProvider,
    );
  }

  /// Modelos disponibles por proveedor
  static const Map<AiProvider, List<String>> availableModels = {
    AiProvider.gemini: ['gemini-2.0-flash-001'],
    AiProvider.deepseek: ['deepseek-chat', 'deepseek-coder'],
    AiProvider.anthropic: ['claude-sonnet-4-20250514', 'claude-haiku-4-20250414'],
  };

  /// URLs para obtener API keys
  static const Map<AiProvider, String> apiKeyUrls = {
    AiProvider.gemini: 'https://makersuite.google.com/app/apikey',
    AiProvider.deepseek: 'https://platform.deepseek.com/api_keys',
    AiProvider.anthropic: 'https://console.anthropic.com/settings/keys',
  };

  String get defaultModel => availableModels[provider]?.first ?? '';
  String get currentModel => selectedModel ?? defaultModel;
}
