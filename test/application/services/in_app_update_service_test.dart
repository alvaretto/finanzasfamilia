import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/in_app_update_service.dart';

void main() {
  group('InAppUpdateService', () {
    late InAppUpdateService service;

    setUp(() {
      service = InAppUpdateService();
    });

    test('es singleton', () {
      final service1 = InAppUpdateService();
      final service2 = InAppUpdateService();

      expect(identical(service1, service2), isTrue);
    });

    test('isUpdateAvailable es false por defecto', () {
      expect(service.isUpdateAvailable, isFalse);
    });

    test('updateInfo es null por defecto', () {
      expect(service.updateInfo, isNull);
    });

    test('shouldForceUpdate retorna false cuando no hay update info', () {
      expect(service.shouldForceUpdate(), isFalse);
    });

    test('shouldForceUpdate acepta threshold personalizado', () {
      expect(service.shouldForceUpdate(staleDaysThreshold: 3), isFalse);
      expect(service.shouldForceUpdate(staleDaysThreshold: 14), isFalse);
    });

    // Tests que requieren Play Store real movidos a:
    // integration_test/services/in_app_update_service_integration_test.dart
  });
}
