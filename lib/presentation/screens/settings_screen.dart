import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';
import '../../application/providers/theme_provider.dart';
import 'bank_notifications_screen.dart';
import 'data_export_import_screen.dart';
import 'family_screen.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';


/// Pantalla de configuración general de la aplicación
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Sección: Apariencia
          const _SectionHeader(title: 'Apariencia', icon: Icons.palette),
          const _ThemeSelector(),
          const Divider(),

          // Sección: Notificaciones
          const _SectionHeader(title: 'Notificaciones', icon: Icons.notifications),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: colorScheme.primary),
            title: const Text('Configurar notificaciones'),
            subtitle: const Text('Alertas de presupuesto y recordatorios'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_balance, color: colorScheme.primary),
            title: const Text('Notificaciones Bancarias'),
            subtitle: const Text('Detectar transacciones automáticamente'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankNotificationsScreen()),
            ),
          ),
          const Divider(),

          // Sección: Familia
          const _SectionHeader(title: 'Familia', icon: Icons.family_restroom),
          ListTile(
            leading: Icon(Icons.group, color: colorScheme.primary),
            title: const Text('Mis Familias'),
            subtitle: const Text('Gestionar familias y miembros'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyScreen()),
            ),
          ),
          const Divider(),

          // Sección: Datos
          const _SectionHeader(title: 'Datos', icon: Icons.storage),
          ListTile(
            leading: Icon(Icons.import_export, color: colorScheme.primary),
            title: const Text('Exportar / Importar'),
            subtitle: const Text('Respaldo y migración de datos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataExportImportScreen()),
            ),
          ),
          const Divider(),

          // Sección: Información
          const _SectionHeader(title: 'Información', icon: Icons.info),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('Versión'),
            subtitle: const Text('5.1'),
          ),
          const Divider(),

          // Sección: Cuenta
          const _SectionHeader(title: 'Cuenta', icon: Icons.account_circle),
          _LogoutTile(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget selector de tema con SegmentedButton
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: Icon(AppThemeMode.light.icon),
                  label: Text(AppThemeMode.light.displayName),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: Icon(AppThemeMode.dark.icon),
                  label: Text(AppThemeMode.dark.displayName),
                ),
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: Icon(AppThemeMode.system.icon),
                  label: Text(AppThemeMode.system.displayName),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (selection) {
                ref.read(themeNotifierProvider.notifier).setTheme(selection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getThemeDescription(currentMode),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Siempre usar tema claro';
      case AppThemeMode.dark:
        return 'Siempre usar tema oscuro';
      case AppThemeMode.system:
        return 'Seguir la configuración del dispositivo';
    }
  }
}

/// Widget para cerrar sesión con confirmación
class _LogoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.logout, color: colorScheme.error),
      title: Text(
        'Cerrar sesión',
        style: TextStyle(color: colorScheme.error),
      ),
      subtitle: const Text('Salir de tu cuenta'),
      onTap: () => _showLogoutDialog(context, ref),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

