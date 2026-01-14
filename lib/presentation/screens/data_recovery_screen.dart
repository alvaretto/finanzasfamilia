import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/providers/database_provider.dart';
import '../../application/providers/sync_status_provider.dart';
import '../../application/providers/user_settings_provider.dart';
import '../../application/services/data_seeding_service.dart';
import '../../data/sync/powersync_database.dart';
import 'main_shell.dart';

/// Pantalla de recuperación de datos
/// Se muestra después del login mientras se sincronizan los datos del usuario
/// desde Supabase hacia la base de datos local.
class DataRecoveryScreen extends ConsumerStatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  ConsumerState<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends ConsumerState<DataRecoveryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Conectando con el servidor...';
  bool _isComplete = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[RECOVERY] initState llamado');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Iniciar recuperación de datos
    _startDataRecovery();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startDataRecovery() async {
    debugPrint('[RECOVERY] _startDataRecovery iniciado');
    try {
      final powerSync = PowerSyncDatabaseManager.instance;
      final db = ref.read(appDatabaseProvider);
      final seedingService = DataSeedingService(db);

      // Paso 1: Conectando
      debugPrint('[RECOVERY] Paso 1: Conectando...');
      _updateStatus('Conectando con el servidor...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 2: Sincronizando datos
      debugPrint('[RECOVERY] Paso 2: Sincronizando...');
      _updateStatus('Sincronizando tus datos...');

      // Esperar la sincronización inicial con timeout de 45 segundos
      debugPrint('[RECOVERY] Llamando reconnectAndSync con timeout 45s');
      final syncSuccess = await powerSync.reconnectAndSync(
        timeout: const Duration(seconds: 45),
      );
      debugPrint('[RECOVERY] reconnectAndSync completado: $syncSuccess');

      // Paso 3: Verificar si hay datos o necesita seeding
      debugPrint('[RECOVERY] Paso 3: Verificando datos...');
      _updateStatus('Verificando datos...');

      // IMPORTANTE: Solo sembrar si no hay datos después de sincronizar
      // Esto permite que los datos sincronizados desde Supabase tengan prioridad
      final seeded = await seedingService.seedIfEmpty();
      debugPrint('[RECOVERY] seedIfEmpty completado: $seeded');

      // Paso 4: Asegurar que existan configuraciones de usuario
      // Esto es crucial para que las preferencias (tema, onboarding) se sincronicen
      // y no se pierdan al reinstalar
      debugPrint('[RECOVERY] Paso 4: Inicializando configuraciones...');
      await _ensureUserSettings();

      // Si recuperamos datos del servidor (no fue necesario sembrar),
      // asumimos que el usuario ya pasó por onboarding previamente.
      if (!seeded && await seedingService.hasUserData()) {
        debugPrint('[RECOVERY] Datos existentes detectados - Auto-completando onboarding');
        final settingsService = ref.read(userSettingsServiceProvider);
        await settingsService.updateOnboardingCompleted(true);
      }


      if (seeded) {
        _updateStatus('Configuración inicial completada');
      } else if (syncSuccess) {
        _updateStatus('Datos recuperados correctamente');
      } else {
        _updateStatus('Usando datos locales');
      }

      debugPrint('[RECOVERY] Paso 4: Completado, navegando a MainShell...');
      setState(() {
        _isComplete = true;
      });

      // Esperar un momento para mostrar el mensaje de éxito
      await Future.delayed(const Duration(seconds: 1));

      // Navegar al dashboard
      if (mounted) {
        debugPrint('[RECOVERY] Navegando a MainShell');
        _navigateToMainShell();
      }
    } catch (e, stack) {
      debugPrint('[RECOVERY] ERROR: $e');
      debugPrint('[RECOVERY] STACK: $stack');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error de conexión: ${e.toString()}';
      });
    }
  }

  Future<void> _ensureUserSettings() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final settingsService = ref.read(userSettingsServiceProvider);
        await settingsService.createInitialSettings(userId);
        debugPrint('[RECOVERY] Configuraciones de usuario verificadas/creadas');
      } else {
        debugPrint('[RECOVERY] No hay usuario autenticado, saltando init settings');
      }
    } catch (e) {
      debugPrint('[RECOVERY] Error inicializando settings: $e');
      // No bloqueamos el flujo por error en settings, usamos defaults
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToMainShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _retrySync() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isComplete = false;
    });
    _startDataRecovery();
  }

  void _continueOffline() {
    // Permitir continuar sin sincronización completa
    _navigateToMainShell();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icono animado
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _hasError
                        ? Icons.cloud_off
                        : _isComplete
                            ? Icons.cloud_done
                            : Icons.cloud_sync,
                    size: 72,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Título
              Text(
                _hasError
                    ? 'Error de sincronización'
                    : _isComplete
                        ? 'Datos recuperados'
                        : 'Recuperando tus datos',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje de estado
              Text(
                _hasError ? (_errorMessage ?? 'Error desconocido') : _statusMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Indicador de progreso o estado de sync
              if (!_hasError && !_isComplete) ...[
                LinearProgressIndicator(
                  backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
                const SizedBox(height: 16),
                // Estado detallado de PowerSync
                if (syncState.isDownloading || syncState.isUploading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        syncState.isDownloading
                            ? Icons.cloud_download
                            : Icons.cloud_upload,
                        size: 16,
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncState.isDownloading
                            ? 'Descargando datos...'
                            : 'Subiendo cambios...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
              ],
              // Botones de error
              if (_hasError) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _retrySync,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary,
                    foregroundColor: colorScheme.primary,
                    minimumSize: const Size(200, 48),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _continueOffline,
                  child: Text(
                    'Continuar sin sincronizar',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ],
              const Spacer(),
              // Nota informativa
              if (!_hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Estamos recuperando todos tus datos financieros. '
                          'Esto solo toma unos segundos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
