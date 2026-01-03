import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../family/presentation/screens/family_screen.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../../transactions/presentation/screens/categories_screen.dart';
import 'notifications_screen.dart';
import 'export_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
                  // TODO: Editar perfil
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
                subtitle: 'MXN - Peso Mexicano',
                onTap: () {
                  // TODO: Cambiar moneda
                },
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
              _SettingsTile(
                icon: Icons.fingerprint,
                title: 'Biometria',
                subtitle: 'Huella digital / Face ID',
                onTap: () {
                  // TODO: Configurar biometria
                },
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contrasena',
                onTap: () {
                  // TODO: Cambiar contrasena
                },
              ),
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Bloqueo Automatico',
                subtitle: '5 minutos',
                onTap: () {
                  // TODO: Configurar timeout
                },
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
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: 'Sincronizacion',
                subtitle: 'Ultima: Hace 5 minutos',
                onTap: () {
                  // TODO: Ver estado de sync
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
                subtitle: 'Crear o restaurar respaldo',
                onTap: () {
                  // TODO: Backup
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
                onTap: () {
                  // TODO: Ver ayuda
                },
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Enviar Comentarios',
                onTap: () {
                  // TODO: Feedback
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Acerca de',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Finanzas Familiares',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '2026 Finanzas Familiares AS',
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
