import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/notification_service.dart';
import 'user_settings_provider.dart';

part 'notification_provider.g.dart';

/// Provider para el servicio de notificaciones
@riverpod
NotificationService notificationService(ref) {
  return NotificationService();
}

/// Estado de configuración de notificaciones
/// MIGRADO: Ahora se obtiene desde UserSettings sincronizado
class NotificationSettings {
  final bool globalEnabled;
  final bool budgetAlertsEnabled;
  final bool recurringRemindersEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;

  const NotificationSettings({
    this.globalEnabled = true,
    this.budgetAlertsEnabled = true,
    this.recurringRemindersEnabled = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
  });

  NotificationSettings copyWith({
    bool? globalEnabled,
    bool? budgetAlertsEnabled,
    bool? recurringRemindersEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
  }) {
    return NotificationSettings(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      recurringRemindersEnabled:
          recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
    );
  }
}

/// Provider para configuración de notificaciones
/// MIGRADO: Delegación completa a UserSettingsService
@riverpod
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  Future<NotificationSettings> build() async {
    // Escuchar cambios en UserSettings y sincronizar
    ref.listen(userSettingsProvider, (previous, next) {
      next.whenData((settings) {
        if (settings != null) {
          state = AsyncData(_fromUserSettings(settings));
        }
      });
    });

    // Estado inicial desde UserSettings
    final userSettings = await ref.watch(userSettingsProvider.future);

    if (userSettings == null) {
      return const NotificationSettings();
    }

    return _fromUserSettings(userSettings);
  }

  /// Convierte UserSettings a NotificationSettings
  NotificationSettings _fromUserSettings(dynamic settings) {
    return NotificationSettings(
      globalEnabled: settings.notificationsEnabled,
      budgetAlertsEnabled: settings.budgetAlertsEnabled,
      recurringRemindersEnabled: settings.recurringRemindersEnabled,
      dailyReminderEnabled: settings.dailyReminderEnabled,
      dailyReminderHour: settings.dailyReminderHour,
    );
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    final userSettingsService = ref.read(userSettingsServiceProvider);

    await userSettingsService.updateNotificationPreferences(
      notificationsEnabled: enabled,
    );

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.setNotificationsEnabled(enabled);

    state = AsyncData(state.value!.copyWith(globalEnabled: enabled));
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final userSettingsService = ref.read(userSettingsServiceProvider);

    await userSettingsService.updateNotificationPreferences(
      budgetAlertsEnabled: enabled,
    );

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.setBudgetAlertsEnabled(enabled);

    state = AsyncData(state.value!.copyWith(budgetAlertsEnabled: enabled));
  }

  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    final userSettingsService = ref.read(userSettingsServiceProvider);

    await userSettingsService.updateNotificationPreferences(
      recurringRemindersEnabled: enabled,
    );

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.setRecurringRemindersEnabled(enabled);

    state = AsyncData(state.value!.copyWith(recurringRemindersEnabled: enabled));
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final userSettingsService = ref.read(userSettingsServiceProvider);

    await userSettingsService.updateNotificationPreferences(
      dailyReminderEnabled: enabled,
    );

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.setDailyReminderEnabled(enabled);

    state = AsyncData(state.value!.copyWith(dailyReminderEnabled: enabled));
  }

  Future<void> setDailyReminderHour(int hour) async {
    final userSettingsService = ref.read(userSettingsServiceProvider);

    await userSettingsService.updateNotificationPreferences(
      dailyReminderHour: hour,
    );

    final notificationService = ref.read(notificationServiceProvider);
    if (state.value?.dailyReminderEnabled ?? false) {
      await notificationService.scheduleDailyReminder(hour: hour);
    }

    state = AsyncData(state.value!.copyWith(dailyReminderHour: hour));
  }
}
