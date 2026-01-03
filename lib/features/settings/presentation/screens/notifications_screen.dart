import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Provider para preferencias de notificaciones
final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) {
  return NotificationPrefsNotifier();
});

class NotificationPrefs {
  final bool enabled;
  final bool budgetAlerts;
  final bool budgetWarnings;
  final bool recurringReminders;
  final bool goalProgress;
  final int budgetWarningThreshold; // Porcentaje

  const NotificationPrefs({
    this.enabled = true,
    this.budgetAlerts = true,
    this.budgetWarnings = true,
    this.recurringReminders = true,
    this.goalProgress = true,
    this.budgetWarningThreshold = 80,
  });

  NotificationPrefs copyWith({
    bool? enabled,
    bool? budgetAlerts,
    bool? budgetWarnings,
    bool? recurringReminders,
    bool? goalProgress,
    int? budgetWarningThreshold,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      budgetWarnings: budgetWarnings ?? this.budgetWarnings,
      recurringReminders: recurringReminders ?? this.recurringReminders,
      goalProgress: goalProgress ?? this.goalProgress,
      budgetWarningThreshold:
          budgetWarningThreshold ?? this.budgetWarningThreshold,
    );
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs());

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  void setBudgetAlerts(bool value) {
    state = state.copyWith(budgetAlerts: value);
  }

  void setBudgetWarnings(bool value) {
    state = state.copyWith(budgetWarnings: value);
  }

  void setRecurringReminders(bool value) {
    state = state.copyWith(recurringReminders: value);
  }

  void setGoalProgress(bool value) {
    state = state.copyWith(goalProgress: value);
  }

  void setBudgetWarningThreshold(int value) {
    state = state.copyWith(budgetWarningThreshold: value);
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.requestPermissions();
    setState(() => _permissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView(
        children: [
          // Estado del permiso
          if (!_permissionGranted)
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permisos requeridos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Activa los permisos para recibir alertas',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.tonal(
                          onPressed: _checkPermission,
                          child: const Text('Activar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Switch principal
          SwitchListTile(
            secondary: Icon(
              prefs.enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: prefs.enabled ? AppColors.primary : Colors.grey,
            ),
            title: const Text('Notificaciones'),
            subtitle: Text(
              prefs.enabled ? 'Activadas' : 'Desactivadas',
            ),
            value: prefs.enabled,
            onChanged: (value) => notifier.setEnabled(value),
          ),

          if (prefs.enabled) ...[
            const Divider(),

            // Seccion: Presupuestos
            _buildSection(
              context,
              title: 'Presupuestos',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.error_outline),
                  title: const Text('Alertas de exceso'),
                  subtitle: const Text(
                    'Notificar cuando excedas un presupuesto',
                  ),
                  value: prefs.budgetAlerts,
                  onChanged: (value) => notifier.setBudgetAlerts(value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Alertas preventivas'),
                  subtitle: Text(
                    'Avisar al llegar al ${prefs.budgetWarningThreshold}%',
                  ),
                  value: prefs.budgetWarnings,
                  onChanged: (value) => notifier.setBudgetWarnings(value),
                ),
                if (prefs.budgetWarnings)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Umbral de alerta: ${prefs.budgetWarningThreshold}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          value: prefs.budgetWarningThreshold.toDouble(),
                          min: 50,
                          max: 95,
                          divisions: 9,
                          label: '${prefs.budgetWarningThreshold}%',
                          onChanged: (value) =>
                              notifier.setBudgetWarningThreshold(value.toInt()),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const Divider(),

            // Seccion: Pagos recurrentes
            _buildSection(
              context,
              title: 'Pagos Recurrentes',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.event_repeat),
                  title: const Text('Recordatorios'),
                  subtitle: const Text(
                    'Avisar un dia antes de pagos programados',
                  ),
                  value: prefs.recurringReminders,
                  onChanged: (value) => notifier.setRecurringReminders(value),
                ),
              ],
            ),

            const Divider(),

            // Seccion: Metas
            _buildSection(
              context,
              title: 'Metas de Ahorro',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Progreso de metas'),
                  subtitle: const Text(
                    'Notificar avances y metas alcanzadas',
                  ),
                  value: prefs.goalProgress,
                  onChanged: (value) => notifier.setGoalProgress(value),
                ),
              ],
            ),

            const Divider(),

            // Probar notificacion
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.instance.showNotification(
                    id: 0,
                    title: 'Prueba de notificacion',
                    body: 'Las notificaciones funcionan correctamente',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificacion de prueba enviada'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Enviar notificacion de prueba'),
              ),
            ),
          ],
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
            AppSpacing.md,
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
