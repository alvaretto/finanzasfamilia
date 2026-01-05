import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackType _selectedType = FeedbackType.suggestion;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userEmail = user?.email ?? 'usuario@finanzas.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Comentarios'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Header
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.feedback, color: Colors.green.shade700, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Tu opinión nos importa!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ayúdanos a mejorar la app con tus comentarios',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tipo de comentario
            Text(
              'Tipo de comentario',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            ...FeedbackType.values.map(
              (type) => RadioListTile<FeedbackType>(
                value: type,
                groupValue: _selectedType,
                onChanged: (value) => setState(() => _selectedType = value!),
                title: Text(type.displayName),
                subtitle: Text(type.description),
                secondary: Icon(type.icon, color: AppColors.primary),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Título/Asunto
            Text(
              'Asunto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Ej: Agregar soporte para criptomonedas',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un asunto';
                }
                if (value.trim().length < 5) {
                  return 'Mínimo 5 caracteres';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Mensaje
            Text(
              'Mensaje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Describe tu sugerencia, problema o comentario...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un mensaje';
                }
                if (value.trim().length < 10) {
                  return 'Mínimo 10 caracteres';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Info del usuario
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información incluida',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(Icons.email, 'Email', userEmail),
                    _buildInfoRow(Icons.phone_android, 'Plataforma', 'Android'),
                    _buildInfoRow(Icons.info_outline, 'Versión', '1.9.1'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Botón enviar
            FilledButton.icon(
              onPressed: _isSending ? null : _sendFeedback,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Enviando...' : 'Enviar Comentarios'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Note
            Text(
              'Nota: Se abrirá tu app de email predeterminada para enviar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final user = ref.read(authProvider).user;
      final userEmail = user?.email ?? 'usuario@finanzas.com';

      // Construir email
      final subject = '${_selectedType.displayName}: ${_titleController.text.trim()}';
      final body = '''
Tipo: ${_selectedType.displayName}
Usuario: $userEmail
Versión: 1.9.1
Plataforma: Android

---

${_messageController.text.trim()}
''';

      final emailUri = Uri(
        scheme: 'mailto',
        path: 'soporte@finanzasfamiliares.com',
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gracias por tus comentarios!'),
              backgroundColor: Colors.green,
            ),
          );

          // Limpiar formulario
          _titleController.clear();
          _messageController.clear();
          setState(() => _selectedType = FeedbackType.suggestion);
        }
      } else {
        throw Exception('No se pudo abrir la app de email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

enum FeedbackType {
  suggestion,
  bug,
  question,
  other;

  String get displayName {
    switch (this) {
      case suggestion:
        return 'Sugerencia';
      case bug:
        return 'Reportar Error';
      case question:
        return 'Pregunta';
      case other:
        return 'Otro';
    }
  }

  String get description {
    switch (this) {
      case suggestion:
        return 'Idea para mejorar la app';
      case bug:
        return 'Algo no funciona correctamente';
      case question:
        return 'Necesitas ayuda con algo';
      case other:
        return 'Otro tipo de comentario';
    }
  }

  IconData get icon {
    switch (this) {
      case suggestion:
        return Icons.lightbulb_outline;
      case bug:
        return Icons.bug_report;
      case question:
        return Icons.help_outline;
      case other:
        return Icons.chat_bubble_outline;
    }
  }
}
