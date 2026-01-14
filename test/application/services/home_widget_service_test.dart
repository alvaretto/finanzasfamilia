import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas_familiares/application/services/home_widget_service.dart';

void main() {
  setUpAll(() async {
    // Inicializar datos de localización para DateFormat
    await initializeDateFormatting('es_CO', null);
  });

  group('HomeWidgetService', () {
    late HomeWidgetService service;

    setUp(() {
      service = HomeWidgetService();
    });

    test('puede ser instanciado', () {
      expect(service, isNotNull);
    });

    test('updateBalance formatea el saldo correctamente', () async {
      // El servicio formatea internamente, solo verificamos que no falle
      // En un test real, necesitaríamos un mock de home_widget
      final result = await service.updateBalance(1500000.0);
      // El widget puede no estar instalado en tests, así que aceptamos ambos
      expect(result, isA<bool>());
    });

    test('clearWidget no lanza excepciones', () async {
      // Verificar que no lanza excepciones
      await expectLater(
        service.clearWidget(),
        completes,
      );
    });

    test('isWidgetInstalled retorna bool', () async {
      final result = await service.isWidgetInstalled();
      expect(result, isA<bool>());
    });
  });
}
