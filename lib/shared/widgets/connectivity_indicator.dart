import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/theme/app_theme.dart';

/// Provider de estado de conectividad
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider que indica si hay conexion a internet
final isConnectedProvider = Provider<AsyncValue<bool>>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.whenData((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

/// Widget que muestra un banner cuando no hay conexion
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);

    return Column(
      children: [
        // Banner de sin conexion
        isConnected.when(
          data: (connected) {
            if (connected) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.warning,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Sin conexion - Modo offline',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Contenido principal
        Expanded(child: child),
      ],
    );
  }
}

/// Widget compacto que muestra un icono de estado de conexion
class ConnectivityIcon extends ConsumerWidget {
  final double size;
  final Color? connectedColor;
  final Color? disconnectedColor;

  const ConnectivityIcon({
    super.key,
    this.size = 20,
    this.connectedColor,
    this.disconnectedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);

    return isConnected.when(
      data: (connected) {
        if (connected) {
          return Icon(
            Icons.wifi,
            size: size,
            color: connectedColor ?? AppColors.success,
          );
        }
        return Icon(
          Icons.wifi_off,
          size: size,
          color: disconnectedColor ?? AppColors.warning,
        );
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(
        Icons.wifi_off,
        size: size,
        color: disconnectedColor ?? AppColors.warning,
      ),
    );
  }
}

/// Mixin para widgets que necesitan reaccionar a cambios de conectividad
mixin ConnectivityAware<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _wasOffline = false;

  /// Llama a [onReconnected] cuando la conexion se restaura
  void listenToConnectivity({required VoidCallback onReconnected}) {
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      next.whenData((isConnected) {
        if (_wasOffline && isConnected) {
          onReconnected();
        }
        _wasOffline = !isConnected;
      });
    });
  }
}
