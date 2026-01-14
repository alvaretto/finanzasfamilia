import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/ai_assistant_provider.dart';
import '../../application/providers/receipt_scanner_provider.dart' as scanner;
import '../../domain/entities/financial_context.dart';
import '../../domain/entities/receipts/parsed_receipt.dart';
import 'transaction_form_screen.dart';

/// Pantalla del chat con el asistente IA "Fina"
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _focusNode.requestFocus();

    await ref.read(aIChatNotifierProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aIChatNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Auto-scroll cuando cambian los mensajes
    ref.listen(aIChatNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fina',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tu asistente financiero',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpiar chat',
              onPressed: () => _showClearDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: chatState.messages.isEmpty
                ? _WelcomeMessage()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return _ChatBubble(
                        message: message,
                        onRetry: message.error != null
                            ? () => ref
                                .read(aIChatNotifierProvider.notifier)
                                .retryLastMessage()
                            : null,
                      );
                    },
                  ),
          ),
          // Campo de entrada
          _MessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            isLoading: chatState.isLoading,
            onSend: _sendMessage,
            onScanReceipt: () => _showScanOptions(context),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text(
          '¿Deseas borrar toda la conversación con Fina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(aIChatNotifierProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              subtitle: const Text('Escanear factura con la cámara'),
              onTap: () {
                Navigator.pop(context);
                _scanReceipt(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                _scanReceipt(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanReceipt({required bool fromCamera}) async {
    final notifier = ref.read(scanner.receiptScanNotifierProvider.notifier);

    if (fromCamera) {
      await notifier.scanFromCamera();
    } else {
      await notifier.scanFromGallery();
    }

    final state = ref.read(scanner.receiptScanNotifierProvider);

    if (!mounted) return;

    switch (state) {
      case scanner.ReceiptScanSuccess(:final receipt):
        _showReceiptConfirmation(receipt);
      case scanner.ReceiptScanError(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      default:
        break;
    }

    notifier.reset();
  }

  void _showReceiptConfirmation(ParsedReceipt receipt) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Factura detectada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReceiptField(
              label: 'Monto',
              value: '\$${receipt.amount.toStringAsFixed(0)}',
              icon: Icons.attach_money,
            ),
            if (receipt.merchant != null)
              _ReceiptField(
                label: 'Comercio',
                value: receipt.merchant!,
                icon: Icons.store,
              ),
            if (receipt.date != null)
              _ReceiptField(
                label: 'Fecha',
                value: '${receipt.date!.day}/${receipt.date!.month}/${receipt.date!.year}',
                icon: Icons.calendar_today,
              ),
            if (receipt.suggestedCategory != null)
              _ReceiptField(
                label: 'Categoría sugerida',
                value: receipt.suggestedCategory!,
                icon: Icons.category,
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    receipt.parseSource == 'ai' ? Icons.auto_awesome : Icons.text_fields,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    receipt.parseSource == 'ai' ? 'Procesado con IA' : 'Procesado localmente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _createTransactionFromReceipt(receipt);
            },
            child: const Text('Registrar gasto'),
          ),
        ],
      ),
    );
  }

  void _createTransactionFromReceipt(ParsedReceipt receipt) {
    // Navegar al formulario de transacción con datos pre-llenados
    final description = receipt.merchant != null
        ? 'Compra en ${receipt.merchant}'
        : 'Gasto escaneado';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          initialType: 'expense',
          initialAmount: receipt.amount,
          initialDescription: description,
        ),
      ),
    );
  }
}

/// Mensaje de bienvenida cuando no hay conversación
class _WelcomeMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🤖',
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Hola! Soy Fina',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Tu asistente financiero personal',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Puedo ayudarte a:',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const _SuggestionChip(
          icon: Icons.insights,
          label: 'Analizar tus gastos',
        ),
        const SizedBox(height: 8),
        const _SuggestionChip(
          icon: Icons.savings,
          label: 'Consejos de ahorro',
        ),
        const SizedBox(height: 8),
        const _SuggestionChip(
          icon: Icons.trending_up,
          label: 'Mejorar tu salud financiera',
        ),
        const SizedBox(height: 8),
        const _SuggestionChip(
          icon: Icons.help_outline,
          label: 'Resolver dudas financieras',
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Burbuja de mensaje del chat
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const _ChatBubble({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              radius: 16,
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : message.error != null
                            ? colorScheme.errorContainer
                            : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: message.isLoading
                      ? _LoadingIndicator()
                      : SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser
                                ? colorScheme.onPrimary
                                : message.error != null
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurface,
                          ),
                        ),
                ),
                if (message.error != null && onRetry != null) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              radius: 16,
              child: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicador de carga mientras la IA responde
class _LoadingIndicator extends StatefulWidget {
  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (1 - (value - 0.5).abs() * 2).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Campo de entrada de mensajes
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onScanReceipt;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón de escanear factura
            IconButton(
              onPressed: isLoading ? null : onScanReceipt,
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Escanear factura',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar un campo de la factura escaneada
class _ReceiptField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReceiptField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
