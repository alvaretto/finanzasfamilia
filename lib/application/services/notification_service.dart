import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de notificaciones locales para Finanzas Familiares
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // IDs de notificaciones
  static const int budgetWarningId = 1000;
  static const int budgetExceededId = 1001;
  static const int recurringReminderBaseId = 2000;
  static const int dailyReminderBaseId = 3000;

  // Keys de SharedPreferences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyBudgetAlertsEnabled = 'budget_alerts_enabled';
  static const String _keyRecurringRemindersEnabled =
      'recurring_reminders_enabled';
  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyDailyReminderHour = 'daily_reminder_hour';

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Manejar tap en notificación
    // Podría navegar a una pantalla específica según el payload
    final payload = response.payload;
    if (payload != null) {
      // TODO: Implementar navegación basada en payload
    }
  }

  /// Solicita permisos de notificación (Android 13+, iOS)
  Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // ============ ALERTAS DE PRESUPUESTO ============

  /// Muestra alerta cuando un presupuesto alcanza el 80%
  Future<void> showBudgetWarning({
    required String categoryName,
    required double percentUsed,
    required double budgetAmount,
    required double spentAmount,
  }) async {
    if (!await _areBudgetAlertsEnabled()) return;

    await _notifications.show(
      budgetWarningId + categoryName.hashCode,
      '⚠️ Presupuesto al ${percentUsed.toStringAsFixed(0)}%',
      '$categoryName: Has gastado \$${spentAmount.toStringAsFixed(0)} '
          'de \$${budgetAmount.toStringAsFixed(0)}',
      _budgetNotificationDetails(),
      payload: 'budget:$categoryName',
    );
  }

  /// Muestra alerta cuando un presupuesto se excede (100%+)
  Future<void> showBudgetExceeded({
    required String categoryName,
    required double percentUsed,
    required double budgetAmount,
    required double spentAmount,
  }) async {
    if (!await _areBudgetAlertsEnabled()) return;

    final excess = spentAmount - budgetAmount;

    await _notifications.show(
      budgetExceededId + categoryName.hashCode,
      '🔴 Presupuesto excedido',
      '$categoryName: Excedido por \$${excess.toStringAsFixed(0)} '
          '(${percentUsed.toStringAsFixed(0)}%)',
      _budgetNotificationDetails(isUrgent: true),
      payload: 'budget:$categoryName',
    );
  }

  NotificationDetails _budgetNotificationDetails({bool isUrgent = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Alertas de Presupuesto',
        channelDescription: 'Notificaciones cuando te acercas al límite',
        importance: isUrgent ? Importance.high : Importance.defaultImportance,
        priority: isUrgent ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ============ RECORDATORIOS DE TRANSACCIONES RECURRENTES ============

  /// Programa recordatorio para una transacción recurrente
  Future<void> scheduleRecurringReminder({
    required int transactionId,
    required String description,
    required double amount,
    required DateTime nextDueDate,
  }) async {
    if (!await _areRecurringRemindersEnabled()) return;

    // Recordatorio un día antes
    final reminderDate = nextDueDate.subtract(const Duration(days: 1));

    if (reminderDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      recurringReminderBaseId + transactionId,
      '📅 Pago programado mañana',
      '$description: \$${amount.toStringAsFixed(0)}',
      tz.TZDateTime.from(reminderDate, tz.local),
      _recurringNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: 'recurring:$transactionId',
    );
  }

  /// Cancela recordatorio de transacción recurrente
  Future<void> cancelRecurringReminder(int transactionId) async {
    await _notifications.cancel(recurringReminderBaseId + transactionId);
  }

  NotificationDetails _recurringNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'recurring_reminders',
        'Recordatorios de Pagos',
        channelDescription: 'Recordatorios de transacciones recurrentes',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ============ RECORDATORIO DIARIO ============

  /// Programa recordatorio diario para registrar gastos
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (!await _isDailyReminderEnabled()) return;

    await _notifications.zonedSchedule(
      dailyReminderBaseId,
      '💰 ¿Registraste tus gastos de hoy?',
      'Mantén tus finanzas al día',
      _nextInstanceOfTime(hour, minute),
      _dailyReminderDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // Guardar configuración
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyReminderHour, hour);
  }

  /// Cancela recordatorio diario
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(dailyReminderBaseId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  NotificationDetails _dailyReminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'Recordatorio Diario',
        channelDescription: 'Recordatorio para registrar gastos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );
  }

  // ============ CONFIGURACIÓN ============

  /// Verifica si las notificaciones están habilitadas globalmente
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Habilita/deshabilita notificaciones globalmente
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (!enabled) {
      await _notifications.cancelAll();
    }
  }

  Future<bool> _areBudgetAlertsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlertsEnabled) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlertsEnabled, enabled);
  }

  Future<bool> _areRecurringRemindersEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRecurringRemindersEnabled) ?? true;
  }

  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecurringRemindersEnabled, enabled);
  }

  Future<bool> _isDailyReminderEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminderEnabled) ?? false;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminderEnabled, enabled);

    if (enabled) {
      final hour = prefs.getInt(_keyDailyReminderHour) ?? 20;
      await scheduleDailyReminder(hour: hour);
    } else {
      await cancelDailyReminder();
    }
  }

  /// Cancela todas las notificaciones pendientes
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
