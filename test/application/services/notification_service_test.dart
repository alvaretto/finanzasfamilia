import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas_familiares/application/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationService();
    });

    test('es singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    test('IDs de notificación están definidos', () {
      expect(NotificationService.budgetWarningId, 1000);
      expect(NotificationService.budgetExceededId, 1001);
      expect(NotificationService.recurringReminderBaseId, 2000);
      expect(NotificationService.dailyReminderBaseId, 3000);
    });

    group('Configuración', () {
      test('notificaciones habilitadas por defecto', () async {
        final enabled = await service.areNotificationsEnabled();
        expect(enabled, isTrue);
      });

      test('puede habilitar alertas de presupuesto', () async {
        await service.setBudgetAlertsEnabled(true);
        // No hay getter público, pero no debería fallar
      });

      // Tests que requieren plugin nativo movidos a:
      // integration_test/services/notification_service_integration_test.dart
    });
  });
}
