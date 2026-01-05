import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ai_chat/domain/models/ai_settings_model.dart';
import '../../../ai_chat/presentation/providers/ai_settings_provider.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(aiSettingsProvider);
      _apiKeyController.text = settings.apiKey ?? '';
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final settings = ref.read(aiSettingsProvider);
      final provider = ref.read(aiProviderInstanceProvider);

      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty && settings.provider != AiProvider.gemini) {
        setState(() {
          _testResult = 'Ingresa tu API key primero';
          _isTesting = false;
        });
        return;
      }

      await provider.initialize(apiKey, model: settings.currentModel);
      final success = await provider.testConnection();

      setState(() {
        _testResult = success
            ? '✓ Conexión exitosa con ${settings.provider.displayName}'
            : '✗ No se pudo conectar. Verifica tu API key.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ Error: ${e.toString()}';
        _isTesting = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final settings = ref.read(aiSettingsProvider);
    final newSettings = settings.copyWith(
      apiKey: _apiKeyController.text.trim(),
    );

    await ref.read(aiSettingsProvider.notifier).saveSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openApiKeyUrl() async {
    final settings = ref.read(aiSettingsProvider);
    final url = AiSettingsModel.apiKeyUrls[settings.provider];
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de IA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configura tu proveedor de IA preferido. '
                      'Sin API key propia, se usará Gemini gratuito con límite de 10 mensajes/hora.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selector de proveedor
          Text(
            'Proveedor',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...AiProvider.values.map((provider) => RadioListTile<AiProvider>(
            title: Text(provider.displayName),
            subtitle: Text(provider.description),
            value: provider,
            groupValue: settings.provider,
            onChanged: (value) {
              if (value != null) {
                ref.read(aiSettingsProvider.notifier).setProvider(value);
                _testResult = null;
              }
            },
          )),
          const SizedBox(height: 24),

          // API Key
          Text(
            'API Key',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              hintText: settings.provider == AiProvider.gemini
                  ? 'Opcional (usa clave del sistema)'
                  : 'Ingresa tu API key',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                  if (_apiKeyController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _apiKeyController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openApiKeyUrl,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text('Obtener API key de ${settings.provider.displayName}'),
          ),
          const SizedBox(height: 24),

          // Selector de modelo
          Text(
            'Modelo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: settings.currentModel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: (AiSettingsModel.availableModels[settings.provider] ?? [])
                .map((model) => DropdownMenuItem(
                      value: model,
                      child: Text(model),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(aiSettingsProvider.notifier).setModel(value);
              }
            },
          ),
          const SizedBox(height: 32),

          // Resultado del test
          if (_testResult != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testResult!.startsWith('✓')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.startsWith('✓')
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.science),
                  label: Text(_isTesting ? 'Probando...' : 'Probar conexión'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Estado actual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado actual',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Proveedor activo',
                    settings.provider.displayName,
                  ),
                  _buildStatusRow(
                    'Modelo',
                    settings.currentModel,
                  ),
                  _buildStatusRow(
                    'API key configurada',
                    settings.useCustomProvider ? 'Sí' : 'No (usando fallback)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
