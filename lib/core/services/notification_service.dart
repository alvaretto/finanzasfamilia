import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Servicio de notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inicializar el servicio
  /// CRÍTICO: Envuelto en try-catch para evitar crashes en dispositivos problemáticos
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    } catch (e) {
      // Log pero no crashear - las notificaciones son opcionales
      debugPrint('Warning: Could not initialize notifications: $e');
      // Marcar como inicializado para evitar reintentos infinitos
      _isInitialized = true;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    // based on response.payload
  }

  /// Solicitar permisos
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Mostrar notificacion inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'finanzas_channel',
        'Finanzas Familiares',
        channelDescription: 'Notificaciones de la app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Warning: Could not show notification: $e');
    }
  }

  /// Programar notificacion
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'finanzas_scheduled',
      'Recordatorios',
      channelDescription: 'Recordatorios programados',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancelar notificacion
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ============ Notificaciones especificas de la app ============

  /// Alerta de presupuesto excedido
  Future<void> notifyBudgetExceeded({
    required String categoryName,
    required double spent,
    required double limit,
  }) async {
    final percentage = ((spent / limit) * 100).toStringAsFixed(0);
    await showNotification(
      id: categoryName.hashCode,
      title: 'Presupuesto excedido',
      body: 'Has gastado $percentage% de tu presupuesto en $categoryName',
      payload: 'budget:$categoryName',
    );
  }

  /// Alerta de presupuesto cerca del limite
  Future<void> notifyBudgetWarning({
    required String categoryName,
    required double spent,
    required double limit,
  }) async {
    final percentage = ((spent / limit) * 100).toStringAsFixed(0);
    await showNotification(
      id: categoryName.hashCode + 1000,
      title: 'Alerta de presupuesto',
      body: 'Llevas $percentage% de tu presupuesto en $categoryName',
      payload: 'budget:$categoryName',
    );
  }

  /// Recordatorio de pago recurrente
  Future<void> notifyRecurringPayment({
    required String description,
    required double amount,
    required DateTime dueDate,
  }) async {
    await showNotification(
      id: description.hashCode,
      title: 'Pago pendiente',
      body: '$description - \$${amount.toStringAsFixed(2)}',
      payload: 'recurring:$description',
    );
  }

  /// Programar recordatorio de recurrente
  Future<void> scheduleRecurringReminder({
    required int id,
    required String description,
    required double amount,
    required DateTime dueDate,
  }) async {
    // Recordar un dia antes
    final reminderDate = dueDate.subtract(const Duration(days: 1));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Pago manana',
        body: '$description - \$${amount.toStringAsFixed(2)}',
        scheduledDate: reminderDate,
        payload: 'recurring:$id',
      );
    }
  }

  /// Meta de ahorro alcanzada
  Future<void> notifyGoalReached({
    required String goalName,
    required double amount,
  }) async {
    await showNotification(
      id: goalName.hashCode,
      title: 'Meta alcanzada!',
      body: 'Felicidades! Completaste tu meta "$goalName"',
      payload: 'goal:$goalName',
    );
  }

  /// Progreso de meta
  Future<void> notifyGoalProgress({
    required String goalName,
    required int percentage,
  }) async {
    await showNotification(
      id: goalName.hashCode + 2000,
      title: 'Progreso de meta',
      body: 'Tu meta "$goalName" va al $percentage%',
      payload: 'goal:$goalName',
    );
  }
}
