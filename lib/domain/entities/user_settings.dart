import 'package:equatable/equatable.dart';

/// Configuración de usuario persistente
class UserSettings extends Equatable {
  final String id;
  final String userId;
  final String themeMode; // 'light', 'dark', 'system'
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool recurringRemindersEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final String currency;
  final String dateFormat;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSettings({
    required this.id,
    required this.userId,
    this.themeMode = 'system',
    this.onboardingCompleted = false,
    this.notificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.recurringRemindersEnabled = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
    this.currency = 'COP',
    this.dateFormat = 'dd/MM/yyyy',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        themeMode,
        onboardingCompleted,
        notificationsEnabled,
        budgetAlertsEnabled,
        recurringRemindersEnabled,
        dailyReminderEnabled,
        dailyReminderHour,
        currency,
        dateFormat,
        createdAt,
        updatedAt,
      ];

  UserSettings copyWith({
    String? id,
    String? userId,
    String? themeMode,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? recurringRemindersEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    String? currency,
    String? dateFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      recurringRemindersEnabled: recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
