import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/attachment_provider.dart';

/// Widget para capturar y mostrar adjuntos de una transacción
class AttachmentPicker extends ConsumerStatefulWidget {
  final String transactionId;
  final bool enableOcr;
  final ValueChanged<double?>? onAmountDetected;

  const AttachmentPicker({
    super.key,
    required this.transactionId,
    this.enableOcr = true,
    this.onAmountDetected,
  });

  @override
  ConsumerState<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends ConsumerState<AttachmentPicker> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(
      attachmentsNotifierProvider(widget.transactionId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        attachmentsAsync.when(
          data: (attachments) => _buildAttachmentsList(context, attachments),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Recibos y Adjuntos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Tomar foto',
              onPressed: _isProcessing ? null : _captureFromCamera,
            ),
            IconButton(
              icon: const Icon(Icons.photo_library),
              tooltip: 'Galería',
              onPressed: _isProcessing ? null : _pickFromGallery,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentsList(
    BuildContext context,
    List<AttachmentData> attachments,
  ) {
    if (attachments.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length + (_isProcessing ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isProcessing && index == 0) {
            return _buildLoadingCard();
          }
          final adjustedIndex = _isProcessing ? index - 1 : index;
          return _buildAttachmentCard(context, attachments[adjustedIndex]);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _showAddOptions,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 32,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'Agregar recibo o factura',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Procesando...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context, AttachmentData attachment) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // Imagen o icono
          InkWell(
            onTap: () => _showAttachmentDetail(context, attachment),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: attachment.ocrAmount != null
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: attachment.isImage
                    ? Image.file(
                        File(attachment.localPath),
                        fit: BoxFit.cover,
                        width: 100,
                        height: 120,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),
          // Badge de monto detectado
          if (attachment.ocrAmount != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  '\$${_formatAmount(attachment.ocrAmount!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Indicador de sincronización
          Positioned(
            top: 4,
            left: 4,
            child: _SyncIndicator(isSynced: attachment.isSynced),
          ),
          // Botón eliminar
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _deleteAttachment(attachment),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 120,
      color: Colors.grey.shade200,
      child: const Icon(Icons.description, size: 32, color: Colors.grey),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              subtitle: const Text('Capturar con la cámara'),
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(
        attachmentsNotifierProvider(widget.transactionId).notifier,
      );
      final result = await notifier.captureFromCamera(
        processOcr: widget.enableOcr,
      );

      if (result != null && result.ocrAmount != null) {
        widget.onAmountDetected?.call(result.ocrAmount);
        if (mounted) {
          _showOcrResultSnackbar(result.ocrAmount!);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(
        attachmentsNotifierProvider(widget.transactionId).notifier,
      );
      final result = await notifier.pickFromGallery(
        processOcr: widget.enableOcr,
      );

      if (result != null && result.ocrAmount != null) {
        widget.onAmountDetected?.call(result.ocrAmount);
        if (mounted) {
          _showOcrResultSnackbar(result.ocrAmount!);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showOcrResultSnackbar(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Monto detectado: \$${amount.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Usar',
          onPressed: () => widget.onAmountDetected?.call(amount),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _deleteAttachment(AttachmentData attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar adjunto'),
        content: const Text('¿Estás seguro de eliminar este adjunto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        attachmentsNotifierProvider(widget.transactionId).notifier,
      );
      await notifier.deleteAttachment(attachment.id);
    }
  }

  void _showAttachmentDetail(BuildContext context, AttachmentData attachment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AttachmentDetailSheet(attachment: attachment),
    );
  }
}

/// Indicador visual de estado de sincronización
class _SyncIndicator extends StatelessWidget {
  final bool isSynced;

  const _SyncIndicator({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSynced
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSynced ? Icons.cloud_done : Icons.cloud_upload,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}

/// Sheet de detalle de un adjunto
class _AttachmentDetailSheet extends ConsumerWidget {
  final AttachmentData attachment;

  const _AttachmentDetailSheet({required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.fileName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              attachment.formattedSize,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            _SyncStatusChip(isSynced: attachment.isSynced),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (attachment.ocrAmount != null)
                    Chip(
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                      label: Text('\$${attachment.ocrAmount!.toStringAsFixed(0)}'),
                      backgroundColor: Colors.green.shade100,
                    ),
                ],
              ),
            ),
            // Imagen
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    if (attachment.isImage)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(attachment.localPath),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    if (attachment.ocrText != null &&
                        attachment.ocrText!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.text_snippet, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Texto detectado (OCR)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text(
                                  attachment.ocrText!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Chip de estado de sincronización
class _SyncStatusChip extends StatelessWidget {
  final bool isSynced;

  const _SyncStatusChip({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSynced
            ? Colors.green.shade100
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_off,
            size: 12,
            color: isSynced ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Sincronizado' : 'Local',
            style: TextStyle(
              fontSize: 10,
              color: isSynced ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
