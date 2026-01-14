import 'package:drift/drift.dart';

/// Tabla de configuración de usuario sincronizada
/// Reemplaza SharedPreferences para persistencia duradera
@DataClassName('UserSettingsEntry')
class UserSettings extends Table {
  /// ID del usuario (PRIMARY KEY)
  TextColumn get userId => text()();

  /// Modo de tema: 'light', 'dark', 'system'
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  /// ¿Completó onboarding?
  BoolColumn get onboardingCompleted => boolean().withDefault(const Constant(false))();

  /// ¿Notificaciones habilitadas?
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();

  /// ¿Alertas de presupuesto habilitadas?
  BoolColumn get budgetAlertsEnabled => boolean().withDefault(const Constant(true))();

  /// ¿Recordatorios de transacciones recurrentes habilitados?
  BoolColumn get recurringRemindersEnabled => boolean().withDefault(const Constant(true))();

  /// ¿Recordatorio diario habilitado?
  BoolColumn get dailyReminderEnabled => boolean().withDefault(const Constant(false))();

  /// Hora del recordatorio diario (0-23)
  IntColumn get dailyReminderHour => integer().withDefault(const Constant(20))();

  /// Moneda preferida (ISO 4217)
  TextColumn get currency => text().withDefault(const Constant('COP'))();

  /// Formato de fecha preferido
  TextColumn get dateFormat => text().withDefault(const Constant('dd/MM/yyyy'))();

  /// Fecha de creación
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
