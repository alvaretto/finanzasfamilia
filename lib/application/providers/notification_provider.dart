import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

part 'notification_provider.g.dart';

/// Provider para el servicio de notificaciones
@riverpod
NotificationService notificationService(ref) {
  return NotificationService();
}

/// Estado de configuración de notificaciones
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
@riverpod
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  static const String _keyGlobal = 'notifications_enabled';
  static const String _keyBudget = 'budget_alerts_enabled';
  static const String _keyRecurring = 'recurring_reminders_enabled';
  static const String _keyDaily = 'daily_reminder_enabled';
  static const String _keyDailyHour = 'daily_reminder_hour';

  @override
  Future<NotificationSettings> build() async {
    final prefs = await SharedPreferences.getInstance();

    return NotificationSettings(
      globalEnabled: prefs.getBool(_keyGlobal) ?? true,
      budgetAlertsEnabled: prefs.getBool(_keyBudget) ?? true,
      recurringRemindersEnabled: prefs.getBool(_keyRecurring) ?? true,
      dailyReminderEnabled: prefs.getBool(_keyDaily) ?? false,
      dailyReminderHour: prefs.getInt(_keyDailyHour) ?? 20,
    );
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGlobal, enabled);

    final service = ref.read(notificationServiceProvider);
    await service.setNotificationsEnabled(enabled);

    state = AsyncData(state.value!.copyWith(globalEnabled: enabled));
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudget, enabled);

    final service = ref.read(notificationServiceProvider);
    await service.setBudgetAlertsEnabled(enabled);

    state = AsyncData(state.value!.copyWith(budgetAlertsEnabled: enabled));
  }

  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecurring, enabled);

    final service = ref.read(notificationServiceProvider);
    await service.setRecurringRemindersEnabled(enabled);

    state = AsyncData(state.value!.copyWith(recurringRemindersEnabled: enabled));
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDaily, enabled);

    final service = ref.read(notificationServiceProvider);
    await service.setDailyReminderEnabled(enabled);

    state = AsyncData(state.value!.copyWith(dailyReminderEnabled: enabled));
  }

  Future<void> setDailyReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyHour, hour);

    final service = ref.read(notificationServiceProvider);
    if (state.value?.dailyReminderEnabled ?? false) {
      await service.scheduleDailyReminder(hour: hour);
    }

    state = AsyncData(state.value!.copyWith(dailyReminderHour: hour));
  }
}
