import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../local/database.dart';

/// Implementación de UserSettingsRepository con Drift
///
/// Responsabilidades:
/// - CRUD de configuración de usuario en SQLite
/// - Sincronización bidireccional con Supabase vía PowerSync
/// - Proporcionar streams reactivos para cambios
class DriftUserSettingsRepository implements UserSettingsRepository {
  final AppDatabase _database;

  DriftUserSettingsRepository(this._database);

  @override
  Stream<UserSettings?> watchSettings() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }

    return (_database.select(_database.userSettings)
          ..where((tbl) => tbl.userId.equals(userId)))
        .watchSingleOrNull()
        .map((entry) => entry != null ? _mapToEntity(entry) : null);
  }

  @override
  Future<UserSettings?> getSettings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final entry = await (_database.select(_database.userSettings)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();

    return entry != null ? _mapToEntity(entry) : null;
  }

  @override
  Future<void> createInitialSettings(String userId) async {
    final now = DateTime.now();

    await _database.into(_database.userSettings).insert(
          UserSettingsCompanion.insert(
            userId: userId,
            themeMode: const Value('system'),
            onboardingCompleted: const Value(false),
            notificationsEnabled: const Value(true),
            budgetAlertsEnabled: const Value(true),
            recurringRemindersEnabled: const Value(true),
            dailyReminderEnabled: const Value(false),
            dailyReminderHour: const Value(20),
            currency: const Value('COP'),
            dateFormat: const Value('dd/MM/yyyy'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await (_database.update(_database.userSettings)
          ..where((tbl) => tbl.userId.equals(settings.userId)))
        .write(
      UserSettingsCompanion(
        themeMode: Value(settings.themeMode),
        onboardingCompleted: Value(settings.onboardingCompleted),
        notificationsEnabled: Value(settings.notificationsEnabled),
        budgetAlertsEnabled: Value(settings.budgetAlertsEnabled),
        recurringRemindersEnabled: Value(settings.recurringRemindersEnabled),
        dailyReminderEnabled: Value(settings.dailyReminderEnabled),
        dailyReminderHour: Value(settings.dailyReminderHour),
        currency: Value(settings.currency),
        dateFormat: Value(settings.dateFormat),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mapea UserSettingsEntry (Drift) a UserSettings (Dominio)
  UserSettings _mapToEntity(UserSettingsEntry entry) {
    return UserSettings(
      id: entry.userId, // user_id es PK en esta tabla
      userId: entry.userId,
      themeMode: entry.themeMode,
      onboardingCompleted: entry.onboardingCompleted,
      notificationsEnabled: entry.notificationsEnabled,
      budgetAlertsEnabled: entry.budgetAlertsEnabled,
      recurringRemindersEnabled: entry.recurringRemindersEnabled,
      dailyReminderEnabled: entry.dailyReminderEnabled,
      dailyReminderHour: entry.dailyReminderHour,
      currency: entry.currency,
      dateFormat: entry.dateFormat,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
