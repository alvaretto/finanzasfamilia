import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../family/presentation/screens/family_screen.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../../transactions/presentation/screens/categories_screen.dart';
import 'notifications_screen.dart';
import 'export_screen.dart';
import 'import_test_data_screen.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';
import 'backup_screen.dart';

/// Versión de la aplicación
const String appVersion = '1.9.1';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final syncState = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracion'),
      ),
      body: ListView(
        children: [
          // Perfil
          _buildSection(
            context,
            title: 'Perfil',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Mi Perfil',
                subtitle: 'Nombre, foto, email',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.family_restroom,
                title: 'Mi Familia',
                subtitle: 'Gestionar grupo familiar',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FamilyScreen()),
                  );
                },
              ),
            ],
          ),

          // Preferencias
          _buildSection(
            context,
            title: 'Preferencias',
            children: [
              _SettingsTile(
                icon: Icons.attach_money,
                title: 'Moneda',
                subtitle: '${userPrefs.currency} - ${userPrefs.currencyName}',
                onTap: () => _showCurrencyDialog(context, ref),
              ),
              SwitchListTile(
                secondary: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primary,
                ),
                title: const Text('Modo Oscuro'),
                subtitle: Text(
                  themeMode == ThemeMode.system
                      ? 'Automatico'
                      : themeMode == ThemeMode.dark
                          ? 'Activado'
                          : 'Desactivado',
                ),
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).state =
                      value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Alertas y recordatorios',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ],
          ),

          // Seguridad
          _buildSection(
            context,
            title: 'Seguridad',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                title: const Text('Biometria'),
                subtitle: Text(
                  userPrefs.biometricEnabled ? 'Activada' : 'Desactivada',
                ),
                value: userPrefs.biometricEnabled,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).setBiometricEnabled(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Biometría activada' : 'Biometría desactivada'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contrasena',
                subtitle: 'Actualizar tu contraseña',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Bloqueo Automatico',
                subtitle: '${userPrefs.autoLockMinutes} minutos',
                onTap: () => _showAutoLockDialog(context, ref),
              ),
            ],
          ),

          // Datos
          _buildSection(
            context,
            title: 'Datos',
            children: [
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categorias',
                subtitle: 'Gestionar categorias personalizadas',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.repeat,
                title: 'Recurrentes',
                subtitle: 'Pagos e ingresos automaticos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecurringScreen()),
                  );
                },
              ),
              _SyncTile(
                syncState: syncState,
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronizando...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  final result = await ref.read(syncServiceProvider.notifier).syncAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result == SyncStatus.success
                              ? 'Sincronización completada'
                              : result == SyncStatus.offline
                                  ? 'Sin conexión a internet'
                                  : 'Error al sincronizar',
                        ),
                        backgroundColor: result == SyncStatus.success
                            ? Colors.green
                            : result == SyncStatus.offline
                                ? Colors.orange
                                : Colors.red,
                      ),
                    );
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Exportar Datos',
                subtitle: 'CSV, PDF',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExportScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Respaldo',
                subtitle: 'Crear y restaurar respaldos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.science_outlined,
                title: 'Datos de Prueba',
                subtitle: 'Generar transacciones fake',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImportTestDataScreen()),
                  );
                },
              ),
            ],
          ),

          // Soporte
          _buildSection(
            context,
            title: 'Soporte',
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Ayuda',
                subtitle: 'Guías y tutoriales',
                onTap: () => _showComingSoonDialog(context, 'Centro de Ayuda'),
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Enviar Comentarios',
                subtitle: 'Tu opinión nos importa',
                onTap: () => _showComingSoonDialog(context, 'Comentarios'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Acerca de',
                subtitle: 'Versión $appVersion',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Finanzas Familiares',
                    applicationVersion: appVersion,
                    applicationLegalese: '© 2026 Finanzas Familiares AS\nDesarrollado con Flutter',
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'App de finanzas personales y familiares con soporte offline-first.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Moneda: ${userPrefs.currency}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // Cerrar sesion
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar Sesion'),
                    content: const Text('¿Estas seguro que deseas cerrar sesion?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Cerrar Sesion'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(authProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Cerrar Sesion',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: onTap,
    );
  }
}

/// Widget para mostrar el estado de sincronización
class _SyncTile extends StatelessWidget {
  final SyncState syncState;
  final VoidCallback onTap;

  const _SyncTile({
    required this.syncState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (syncState.status) {
      SyncStatus.syncing => Icons.sync,
      SyncStatus.success => Icons.cloud_done_outlined,
      SyncStatus.error => Icons.cloud_off_outlined,
      SyncStatus.offline => Icons.cloud_off_outlined,
      SyncStatus.idle => Icons.cloud_sync_outlined,
    };

    final iconColor = switch (syncState.status) {
      SyncStatus.syncing => AppColors.primary,
      SyncStatus.success => Colors.green,
      SyncStatus.error => Colors.red,
      SyncStatus.offline => Colors.orange,
      SyncStatus.idle => AppColors.primary,
    };

    return ListTile(
      leading: syncState.status == SyncStatus.syncing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Icon(icon, color: iconColor),
      title: const Text('Sincronizacion'),
      subtitle: Text(
        syncState.status == SyncStatus.syncing
            ? 'Sincronizando...'
            : 'Última: ${syncState.lastSyncFormatted}',
      ),
      trailing: Icon(
        Icons.refresh,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: syncState.status == SyncStatus.syncing ? null : onTap,
    );
  }
}

/// Dialogo para seleccionar moneda
void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
  final currencies = [
    ('COP', 'Peso Colombiano', '🇨🇴'),
    ('USD', 'Dólar Estadounidense', '🇺🇸'),
    ('EUR', 'Euro', '🇪🇺'),
    ('MXN', 'Peso Mexicano', '🇲🇽'),
    ('ARS', 'Peso Argentino', '🇦🇷'),
    ('PEN', 'Sol Peruano', '🇵🇪'),
    ('CLP', 'Peso Chileno', '🇨🇱'),
    ('BRL', 'Real Brasileño', '🇧🇷'),
  ];

  final currentCurrency = ref.read(userPreferencesProvider).currency;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Seleccionar Moneda'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            final (code, name, flag) = currencies[index];
            final isSelected = code == currentCurrency;
            return ListTile(
              leading: Text(flag, style: const TextStyle(fontSize: 24)),
              title: Text(code),
              subtitle: Text(name),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(userPreferencesProvider.notifier).setCurrency(code);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Moneda cambiada a $code'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Dialogo para seleccionar tiempo de bloqueo automático
void _showAutoLockDialog(BuildContext context, WidgetRef ref) {
  final options = [1, 2, 5, 10, 15, 30];
  final currentMinutes = ref.read(userPreferencesProvider).autoLockMinutes;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bloqueo Automático'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((minutes) {
          final isSelected = minutes == currentMinutes;
          return ListTile(
            title: Text('$minutes ${minutes == 1 ? 'minuto' : 'minutos'}'),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            selected: isSelected,
            onTap: () {
              ref.read(userPreferencesProvider.notifier).setAutoLockMinutes(minutes);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Dialogo para funciones próximamente disponibles
void _showComingSoonDialog(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.construction, size: 48, color: AppColors.primary),
      title: Text(feature),
      content: const Text(
        'Esta función estará disponible próximamente.\n\n'
        '¡Gracias por tu paciencia!',
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
