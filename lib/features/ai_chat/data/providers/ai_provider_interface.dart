/// Interface base para todos los proveedores de IA
/// Permite intercambiar proveedores sin cambiar el código del chat

abstract class AiProviderInterface {
  /// Nombre del proveedor para mostrar en UI
  String get providerName;

  /// Si el proveedor está inicializado y listo
  bool get isInitialized;

  /// Inicializar con API key
  Future<void> initialize(String apiKey, {String? model});

  /// Enviar mensaje y obtener respuesta
  Future<String> sendMessage({
    required String message,
    required String systemPrompt,
    List<Map<String, String>>? history,
  });

  /// Probar conexión con la API
  Future<bool> testConnection();
}
