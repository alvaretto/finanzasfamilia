import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/connectivity_provider.dart';
import '../../application/providers/sync_status_provider.dart';

/// Indicador visual del estado de sincronización
///
/// Muestra un icono que representa el estado actual:
/// - Verde (cloud_done): Sincronizado
/// - Naranja (sync): Sincronizando
/// - Gris (cloud_off): Sin conexión
/// - Rojo (cloud_off): Error de sync
class SyncStatusIndicator extends ConsumerWidget {
  /// Si es true, muestra también texto descriptivo
  final bool showLabel;

  /// Si es true, permite tap para ver detalles
  final bool interactive;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);

    final (icon, color, label) = _getIndicatorData(syncState, connectivity);

    final indicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(icon, color, syncState.isSyncing),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (!interactive) return indicator;

    return GestureDetector(
      onTap: () => _showSyncDetails(context, ref, syncState, connectivity),
      child: Tooltip(
        message: label,
        child: indicator,
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color, bool isSyncing) {
    if (isSyncing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(icon, color: color, size: 20);
  }

  (IconData, Color, String) _getIndicatorData(
    SyncState syncState,
    ConnectivityStatus connectivity,
  ) {
    // Sin conexión
    if (connectivity == ConnectivityStatus.offline) {
      return (Icons.cloud_off, Colors.grey, 'Sin conexión');
    }

    // Verificando conexión
    if (connectivity == ConnectivityStatus.checking) {
      return (Icons.cloud_queue, Colors.grey, 'Verificando...');
    }

    // Hay errores de sync
    if (syncState.errors.isNotEmpty) {
      return (Icons.cloud_off, Colors.red, 'Error de sync');
    }

    // Sincronizando
    if (syncState.isSyncing) {
      return (Icons.sync, Colors.orange, 'Sincronizando...');
    }

    // Conectado y sincronizado
    if (syncState.isConnected) {
      return (Icons.cloud_done, Colors.green, 'Sincronizado');
    }

    // Desconectado de PowerSync pero con internet
    return (Icons.cloud_queue, Colors.grey, 'Pendiente');
  }

  void _showSyncDetails(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ConnectivityStatus connectivity,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SyncDetailsSheet(
        syncState: syncState,
        connectivity: connectivity,
        onRetrySync: () {
          // Aquí se puede forzar una sincronización
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sincronización iniciada'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

/// Hoja de detalles de sincronización
class _SyncDetailsSheet extends StatelessWidget {
  final SyncState syncState;
  final ConnectivityStatus connectivity;
  final VoidCallback onRetrySync;

  const _SyncDetailsSheet({
    required this.syncState,
    required this.connectivity,
    required this.onRetrySync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Sincronización',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Detalles
          _buildDetailRow(
            'Conexión',
            connectivity == ConnectivityStatus.online
                ? 'Conectado'
                : 'Sin conexión',
            connectivity == ConnectivityStatus.online
                ? Icons.wifi
                : Icons.wifi_off,
          ),

          _buildDetailRow(
            'PowerSync',
            syncState.isConnected ? 'Conectado' : 'Desconectado',
            syncState.isConnected ? Icons.cloud : Icons.cloud_off,
          ),

          if (syncState.lastSyncTime != null)
            _buildDetailRow(
              'Última sync',
              _formatDateTime(syncState.lastSyncTime!),
              Icons.schedule,
            ),

          // Errores
          if (syncState.errors.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Errores recientes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...syncState.errors.take(3).map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
          ],

          const SizedBox(height: 24),

          // Botón de reintentar
          if (connectivity == ConnectivityStatus.online)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetrySync,
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (connectivity == ConnectivityStatus.offline) {
      return Icons.cloud_off;
    }
    if (syncState.errors.isNotEmpty) return Icons.error_outline;
    if (syncState.isSyncing) return Icons.sync;
    if (syncState.isConnected) return Icons.cloud_done;
    return Icons.cloud_queue;
  }

  Color _getStatusColor() {
    if (connectivity == ConnectivityStatus.offline) return Colors.grey;
    if (syncState.errors.isNotEmpty) return Colors.red;
    if (syncState.isSyncing) return Colors.orange;
    if (syncState.isConnected) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText() {
    if (connectivity == ConnectivityStatus.offline) {
      return 'Sin conexión a internet';
    }
    if (syncState.errors.isNotEmpty) {
      return 'Error de sincronización';
    }
    if (syncState.isSyncing) {
      return 'Sincronizando datos...';
    }
    if (syncState.isConnected) {
      return 'Todos los datos sincronizados';
    }
    return 'Pendiente de sincronización';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
