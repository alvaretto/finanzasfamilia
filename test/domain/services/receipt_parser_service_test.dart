import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/services/receipt_parser_service.dart';

void main() {
  late ReceiptParserService parser;

  setUp(() {
    parser = ReceiptParserService();
  });

  group('ReceiptParserService - Extracción de montos', () {
    test('extrae monto con formato TOTAL: \$85.400', () {
      const ocrText = '''
        ALMACENES EXITO
        NIT: 890.900.608-9

        Arroz x2    12.000
        Leche x3     9.600

        TOTAL: \$85.400

        Gracias por su compra
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(85400.0));
    });

    test('extrae monto con formato Total a pagar: \$125,000', () {
      const ocrText = '''
        JUMBO

        Total a pagar: \$125,000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(125000.0));
    });

    test('extrae monto con formato VALOR TOTAL 45000', () {
      const ocrText = '''
        TIENDA D1

        VALOR TOTAL 45000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(45000.0));
    });

    test('extrae monto grande correctamente', () {
      const ocrText = '''
        HOMECENTER

        TOTAL: \$1.250.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(1250000.0));
    });

    test('retorna null si no hay monto válido', () {
      const ocrText = '''
        Texto sin monto válido
        Solo palabras
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNull);
    });

    test('ignora montos muy pequeños (menos de 100)', () {
      const ocrText = '''
        TIENDA
        IVA: 50
        No hay total claro
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNull);
    });
  });

  group('ReceiptParserService - Extracción de comercios conocidos', () {
    test('detecta EXITO', () {
      const ocrText = '''
        ALMACENES EXITO S.A.
        TOTAL: \$50.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant?.toLowerCase(), contains('exito'));
    });

    test('detecta CARULLA', () {
      const ocrText = '''
        CARULLA EXPRESS
        TOTAL: \$75.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant?.toLowerCase(), contains('carulla'));
    });

    test('detecta D1', () {
      const ocrText = '''
        TIENDAS D1
        TOTAL: \$25.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant?.toLowerCase(), contains('d1'));
    });

    test('detecta RAPPI', () {
      const ocrText = '''
        RAPPI S.A.S
        TOTAL: \$35.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant?.toLowerCase(), contains('rappi'));
    });

    test('detecta MC DONALDS', () {
      const ocrText = '''
        MC DONALDS COLOMBIA
        TOTAL: \$28.900
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant, isNotNull);
    });

    test('detecta JUAN VALDEZ', () {
      const ocrText = '''
        JUAN VALDEZ CAFE
        TOTAL: \$15.500
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.merchant?.toLowerCase(), contains('juan'));
    });
  });

  group('ReceiptParserService - Extracción de fechas', () {
    test('extrae fecha formato DD/MM/YYYY', () {
      const ocrText = '''
        EXITO
        Fecha: 15/01/2026
        TOTAL: \$50.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      final date = result?.date;
      expect(date, isNotNull);
      expect(date?.day, equals(15));
      expect(date?.month, equals(1));
      expect(date?.year, equals(2026));
    });

    test('extrae fecha formato DD-MM-YY', () {
      const ocrText = '''
        CARULLA
        11-01-26
        TOTAL: \$30.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      final date = result?.date;
      expect(date, isNotNull);
      expect(date?.day, equals(11));
      expect(date?.month, equals(1));
      expect(date?.year, equals(2026));
    });

    test('extrae fecha formato DD MON YYYY', () {
      const ocrText = '''
        JUMBO
        15 ENE 2026
        TOTAL: \$100.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      final date = result?.date;
      expect(date, isNotNull);
      expect(date?.day, equals(15));
      expect(date?.month, equals(1));
      expect(date?.year, equals(2026));
    });
  });

  group('ReceiptParserService - Sugerencia de categorías', () {
    test('sugiere Alimentación para supermercados', () {
      const ocrText = '''
        ALMACENES EXITO
        TOTAL: \$85.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.suggestedCategory, equals('Alimentación'));
    });

    test('sugiere Restaurantes para comida rápida', () {
      const ocrText = '''
        RAPPI
        Comida
        TOTAL: \$35.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.suggestedCategory, equals('Restaurantes'));
    });

    test('sugiere Entretenimiento para cines', () {
      const ocrText = '''
        CINECOLOMBIA
        TOTAL: \$45.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.suggestedCategory, equals('Entretenimiento'));
    });

    test('sugiere Servicios para empresas de telecomunicaciones', () {
      const ocrText = '''
        CLARO COLOMBIA
        Factura mensual
        TOTAL: \$89.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.suggestedCategory, equals('Servicios'));
    });

    test('sugiere Hogar para tiendas de hogar', () {
      const ocrText = '''
        HOMECENTER
        TOTAL: \$250.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.suggestedCategory, equals('Hogar'));
    });
  });

  group('ReceiptParserService - Confianza del parsing', () {
    test('confianza alta con monto, comercio y fecha', () {
      const ocrText = '''
        ALMACENES EXITO
        Fecha: 15/01/2026
        TOTAL: \$85.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.confidence, greaterThanOrEqualTo(0.8));
    });

    test('confianza media solo con monto y comercio', () {
      const ocrText = '''
        CARULLA
        TOTAL: \$50.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result?.confidence, greaterThanOrEqualTo(0.5));
      expect(result?.confidence, lessThan(1.0));
    });

    test('confianza baja solo con monto', () {
      const ocrText = '''
        TIENDA DESCONOCIDA
        TOTAL: \$30.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.confidence, greaterThanOrEqualTo(0.5));
    });
  });

  group('ReceiptParserService - ParseSource', () {
    test('parseSource es siempre regex', () {
      const ocrText = '''
        EXITO
        TOTAL: \$50.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.parseSource, equals('regex'));
    });
  });

  group('ReceiptParserService - Casos edge', () {
    test('maneja texto vacío', () {
      final result = parser.parse('');
      expect(result, isNull);
    });

    test('maneja texto con solo espacios', () {
      final result = parser.parse('   \n\t  ');
      expect(result, isNull);
    });

    test('maneja OCR con ruido', () {
      const ocrText = '''
        @#\$% EXITO !!!
        T0TAL: \$45.OOO
        TOTAL: \$45.000
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(45000.0));
    });

    test('prioriza TOTAL sobre subtotales', () {
      // TOTAL aparece primero en la búsqueda de patrones
      const ocrText = '''
        EXITO
        TOTAL: \$47.600
        Subtotal: \$40.000
        IVA: \$7.600
      ''';

      final result = parser.parse(ocrText);

      expect(result, isNotNull);
      expect(result!.amount, equals(47600.0));
    });
  });
}
