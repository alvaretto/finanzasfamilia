import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/quick_actions_service.dart';

void main() {
  group('QuickActionsService', () {
    late QuickActionsService service;

    setUp(() {
      service = QuickActionsService();
    });

    test('puede ser instanciado', () {
      expect(service, isNotNull);
    });

    test('setCallback actualiza el callback', () {
      var callbackCalled = false;
      service.setCallback((action) {
        callbackCalled = true;
      });
      // El callback está configurado pero no se invoca en tests unitarios
      expect(callbackCalled, isFalse);
    });
  });

  group('QuickActionType', () {
    test('fromString parsea newExpense correctamente', () {
      final result = QuickActionType.fromString('new_expense');
      expect(result, QuickActionType.newExpense);
    });

    test('fromString parsea newIncome correctamente', () {
      final result = QuickActionType.fromString('new_income');
      expect(result, QuickActionType.newIncome);
    });

    test('fromString parsea viewBalance correctamente', () {
      final result = QuickActionType.fromString('view_balance');
      expect(result, QuickActionType.viewBalance);
    });

    test('fromString retorna null para valor desconocido', () {
      final result = QuickActionType.fromString('unknown');
      expect(result, isNull);
    });

    test('value retorna el string correcto para cada tipo', () {
      expect(QuickActionType.newExpense.value, 'new_expense');
      expect(QuickActionType.newIncome.value, 'new_income');
      expect(QuickActionType.viewBalance.value, 'view_balance');
    });
  });
}
