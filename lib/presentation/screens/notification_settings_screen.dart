import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/notification_provider.dart';

/// Pantalla de configuración de notificaciones
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (settings) => _buildContent(context, ref, settings),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);

    return ListView(
      children: [
        // Notificaciones globales
        SwitchListTile(
          title: const Text('Notificaciones'),
          subtitle: const Text('Activar/desactivar todas las notificaciones'),
          value: settings.globalEnabled,
          onChanged: (value) => notifier.setGlobalEnabled(value),
          secondary: Icon(
            settings.globalEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: settings.globalEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),

        const Divider(),

        // Sección de alertas de presupuesto
        _SectionHeader(
          title: 'Alertas de Presupuesto',
          enabled: settings.globalEnabled,
        ),
        SwitchListTile(
          title: const Text('Alertas de presupuesto'),
          subtitle: const Text('Avisar cuando llegues al 80% o excedas'),
          value: settings.budgetAlertsEnabled && settings.globalEnabled,
          onChanged: settings.globalEnabled
              ? (value) => notifier.setBudgetAlertsEnabled(value)
              : null,
          secondary: const Icon(Icons.pie_chart),
        ),

        const Divider(),

        // Sección de recordatorios
        _SectionHeader(
          title: 'Recordatorios',
          enabled: settings.globalEnabled,
        ),
        SwitchListTile(
          title: const Text('Pagos recurrentes'),
          subtitle: const Text('Recordar un día antes de cada pago'),
          value: settings.recurringRemindersEnabled && settings.globalEnabled,
          onChanged: settings.globalEnabled
              ? (value) => notifier.setRecurringRemindersEnabled(value)
              : null,
          secondary: const Icon(Icons.repeat),
        ),
        SwitchListTile(
          title: const Text('Recordatorio diario'),
          subtitle: Text(
            settings.dailyReminderEnabled
                ? 'Recordar a las ${settings.dailyReminderHour}:00'
                : 'Recordar registrar gastos del día',
          ),
          value: settings.dailyReminderEnabled && settings.globalEnabled,
          onChanged: settings.globalEnabled
              ? (value) => notifier.setDailyReminderEnabled(value)
              : null,
          secondary: const Icon(Icons.today),
        ),
        if (settings.dailyReminderEnabled && settings.globalEnabled)
          ListTile(
            title: const Text('Hora del recordatorio'),
            subtitle: Text('${settings.dailyReminderHour}:00'),
            leading: const SizedBox(width: 24),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTime(context, ref, settings.dailyReminderHour),
          ),

        const Divider(),

        // Información
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Las notificaciones te ayudan a mantener tus finanzas '
            'bajo control. Recibirás alertas cuando te acerques '
            'a tus límites de presupuesto o tengas pagos próximos.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    int currentHour,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      await ref
          .read(notificationSettingsNotifierProvider.notifier)
          .setDailyReminderHour(time.hour);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool enabled;

  const _SectionHeader({
    required this.title,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
    );
  }
}
