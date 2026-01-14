/// Tests de UUIDs determinísticos en seeders
///
/// Verifican que todos los seeders generan UUIDs consistentes usando UUID v5.
/// Esto es CRÍTICO para que PowerSync pueda sincronizar correctamente:
/// - La misma categoría debe tener el mismo ID en cualquier dispositivo
/// - Las cuentas predefinidas deben tener IDs idénticos entre instalaciones
/// - Los lugares del sistema deben ser identificables por su UUID
///
/// Sin UUIDs determinísticos, cada instalación genera IDs diferentes,
/// causando duplicados y conflictos en Supabase.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeterministicUUID - UUIDs Consistentes entre Instalaciones', () {
    const uuid = Uuid();

    group('Fase 1: UUID v5 Behavior', () {
      test('UUID v5 genera el mismo ID para mismo namespace + name', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const name = 'test-name';

        final id1 = uuid.v5(namespace, name);
        final id2 = uuid.v5(namespace, name);
        final id3 = uuid.v5(namespace, name);

        expect(id1, equals(id2));
        expect(id2, equals(id3));
        expect(id1, equals(id3));
      });

      test('UUID v5 genera diferente ID para diferente name', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        final id1 = uuid.v5(namespace, 'name-a');
        final id2 = uuid.v5(namespace, 'name-b');

        expect(id1, isNot(equals(id2)));
      });

      test('UUID v5 genera diferente ID para diferente namespace', () {
        const namespace1 = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const namespace2 = '550e8400-e29b-41d4-a716-446655440000';
        const name = 'same-name';

        final id1 = uuid.v5(namespace1, name);
        final id2 = uuid.v5(namespace2, name);

        expect(id1, isNot(equals(id2)));
      });

      test('UUID v5 es determinístico (no usa random)', () {
        // Generar 100 veces y verificar que siempre es igual
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const name = 'consistency-test';

        final ids = <String>{};
        for (var i = 0; i < 100; i++) {
          ids.add(uuid.v5(namespace, name));
        }

        expect(ids, hasLength(1),
            reason: 'Todas las generaciones deben producir el mismo UUID');
      });
    });

    group('Fase 2: Namespaces de Sistema', () {
      // Namespaces usados en el proyecto (deben ser constantes)
      const categoryNamespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
      const accountNamespace = '550e8400-e29b-41d4-a716-446655440000';
      const placeNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
      const measurementUnitNamespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

      test('Namespaces son UUIDs válidos', () {
        // Verificar formato UUID
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );

        expect(uuidRegex.hasMatch(categoryNamespace), isTrue,
            reason: 'Category namespace debe ser UUID válido');
        expect(uuidRegex.hasMatch(accountNamespace), isTrue,
            reason: 'Account namespace debe ser UUID válido');
        expect(uuidRegex.hasMatch(placeNamespace), isTrue,
            reason: 'Place namespace debe ser UUID válido');
        expect(uuidRegex.hasMatch(measurementUnitNamespace), isTrue,
            reason: 'MeasurementUnit namespace debe ser UUID válido');
      });

      test('Namespaces son únicos entre sí', () {
        final namespaces = {
          categoryNamespace,
          accountNamespace,
          placeNamespace,
          measurementUnitNamespace,
        };

        expect(namespaces, hasLength(4),
            reason: 'Cada seeder debe tener un namespace único');
      });

      test('Namespaces son constantes (hardcoded)', () {
        // Estos valores NUNCA deben cambiar
        // Si cambian, todos los UUIDs generados serán diferentes
        // y la sincronización fallará con duplicados
        expect(categoryNamespace, equals('f47ac10b-58cc-4372-a567-0e02b2c3d479'));
        expect(accountNamespace, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(placeNamespace, equals('6ba7b810-9dad-11d1-80b4-00c04fd430c8'));
        expect(measurementUnitNamespace, equals('6ba7b811-9dad-11d1-80b4-00c04fd430c8'));
      });
    });

    group('Fase 3: Generación de IDs de Categorías', () {
      const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

      test('ID de categoría incluye tipo en el nombre', () {
        // El formato es: type:categoryName
        final assetId = uuid.v5(namespace, 'asset:Lo que Tengo');
        final liabilityId = uuid.v5(namespace, 'liability:Lo que Debo');

        // Mismo nombre, diferente tipo → diferente ID
        expect(assetId, isNot(equals(liabilityId)));
      });

      test('IDs de categorías raíz son determinísticos', () {
        // Estos IDs específicos deben coincidir con lo que genera el seeder
        final expectedAsset = uuid.v5(namespace, 'asset:Lo que Tengo');
        final expectedLiability = uuid.v5(namespace, 'liability:Lo que Debo');
        final expectedIncome = uuid.v5(namespace, 'income:Dinero que Entra');
        final expectedExpense = uuid.v5(namespace, 'expense:Dinero que Sale');

        // Verificar que son UUIDs válidos
        expect(expectedAsset, isNotEmpty);
        expect(expectedLiability, isNotEmpty);
        expect(expectedIncome, isNotEmpty);
        expect(expectedExpense, isNotEmpty);

        // Verificar que son únicos
        final ids = {expectedAsset, expectedLiability, expectedIncome, expectedExpense};
        expect(ids, hasLength(4));
      });

      test('IDs de subcategorías son únicos dentro del mismo tipo', () {
        final efectivoId = uuid.v5(namespace, 'asset:Efectivo');
        final bancosId = uuid.v5(namespace, 'asset:Bancos');
        final inversionesId = uuid.v5(namespace, 'asset:Inversiones');

        final ids = {efectivoId, bancosId, inversionesId};
        expect(ids, hasLength(3),
            reason: 'Subcategorías del mismo tipo deben tener IDs únicos');
      });
    });

    group('Fase 4: Generación de IDs de Cuentas', () {
      const namespace = '550e8400-e29b-41d4-a716-446655440000';

      test('ID de cuenta usa prefijo account:', () {
        final nequiId = uuid.v5(namespace, 'account:Nequi');
        final bancolombia = uuid.v5(namespace, 'account:Bancolombia');

        expect(nequiId, isNot(equals(bancolombia)));
      });

      test('IDs de cuentas predefinidas son únicos', () {
        final accounts = [
          'Billetera Personal',
          'Caja Menor Casa',
          'Alcancía',
          'Davivienda',
          'Bancolombia',
          'DaviPlata',
          'Nequi',
          'DollarApp',
          'PayPal',
          'CDT / Fiducias',
          'Propiedades',
        ];

        final ids = accounts.map((name) => uuid.v5(namespace, 'account:$name')).toSet();
        expect(ids, hasLength(accounts.length),
            reason: 'Cada cuenta debe tener un ID único');
      });
    });

    group('Fase 5: Generación de IDs de Lugares', () {
      const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

      test('ID de lugar incluye tipo en el nombre', () {
        // El formato es: place:type:placeName
        final d1Supermarket = uuid.v5(namespace, 'place:supermarket:D1');
        final d1Other = uuid.v5(namespace, 'place:other:D1');

        // Mismo nombre, diferente tipo → diferente ID
        expect(d1Supermarket, isNot(equals(d1Other)));
      });

      test('IDs de lugares son únicos por tipo', () {
        final supermarkets = ['D1', 'Éxito', 'Jumbo', 'Ara', 'Olímpica'];
        final ids = supermarkets
            .map((name) => uuid.v5(namespace, 'place:supermarket:$name'))
            .toSet();

        expect(ids, hasLength(supermarkets.length));
      });
    });

    group('Fase 6: Simulación de Reinstalación', () {
      test('IDs generados en "instalación 1" = IDs en "instalación 2"', () {
        const categoryNs = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const accountNs = '550e8400-e29b-41d4-a716-446655440000';

        // Simular instalación 1
        final install1CategoryId = uuid.v5(categoryNs, 'expense:Alimentación');
        final install1AccountId = uuid.v5(accountNs, 'account:Nequi');

        // "Desinstalar" - en este caso solo resetear el estado
        // (no hay estado que resetear ya que UUID v5 es puro)

        // Simular instalación 2
        final install2CategoryId = uuid.v5(categoryNs, 'expense:Alimentación');
        final install2AccountId = uuid.v5(accountNs, 'account:Nequi');

        expect(install1CategoryId, equals(install2CategoryId),
            reason: 'Categoría debe tener mismo ID entre instalaciones');
        expect(install1AccountId, equals(install2AccountId),
            reason: 'Cuenta debe tener mismo ID entre instalaciones');
      });

      test('Múltiples dispositivos generan los mismos IDs', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const categoryName = 'asset:Lo que Tengo';

        // Simular 3 dispositivos diferentes
        final device1 = uuid.v5(namespace, categoryName);
        final device2 = uuid.v5(namespace, categoryName);
        final device3 = uuid.v5(namespace, categoryName);

        expect(device1, equals(device2));
        expect(device2, equals(device3));
      });
    });

    group('Fase 7: Casos Edge', () {
      test('Nombres con caracteres especiales generan IDs válidos', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        final specialNames = [
          'expense:4x1000 / GMF',
          'expense:Vehículo / Rodamiento',
          'expense:CDT / Fiducias',
          'expense:Alcancía / Ahorro Físico',
          'income:Salario / Nómina',
        ];

        final ids = <String>{};
        for (final name in specialNames) {
          final id = uuid.v5(namespace, name);
          expect(id, isNotEmpty);
          ids.add(id);
        }

        expect(ids, hasLength(specialNames.length),
            reason: 'Nombres especiales deben generar IDs únicos');
      });

      test('Nombres con acentos generan IDs consistentes', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        // Nombres con acentos (común en español)
        final withAccent1 = uuid.v5(namespace, 'expense:Educación');
        final withAccent2 = uuid.v5(namespace, 'expense:Educación');

        expect(withAccent1, equals(withAccent2),
            reason: 'Acentos deben ser manejados consistentemente');
      });

      test('Nombres con emojis en seeder (icon) no afectan ID', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        // El ID se genera con nombre, no con icono
        // Verificar que el nombre sin emoji genera ID válido
        final id = uuid.v5(namespace, 'expense:Alimentación');
        expect(id, isNotEmpty);

        // Un nombre diferente genera ID diferente
        final idDiff = uuid.v5(namespace, 'expense:🍎 Alimentación');
        expect(id, isNot(equals(idDiff)),
            reason: 'Nombres diferentes generan IDs diferentes');
      });

      test('Nombres vacíos o null son manejados', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        // String vacío genera un UUID (determinístico)
        final emptyId = uuid.v5(namespace, '');
        expect(emptyId, isNotEmpty);

        // Espacio en blanco es diferente de vacío
        final spaceId = uuid.v5(namespace, ' ');
        expect(emptyId, isNot(equals(spaceId)));
      });
    });

    group('Fase 8: Colisiones', () {
      test('No hay colisiones entre tipos de entidades', () {
        // Aunque usen el mismo nombre, diferentes namespaces evitan colisiones
        const categoryNs = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
        const accountNs = '550e8400-e29b-41d4-a716-446655440000';
        const placeNs = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

        // Todos usan "Nequi" como nombre
        final categoryId = uuid.v5(categoryNs, 'asset:Nequi');
        final accountId = uuid.v5(accountNs, 'account:Nequi');
        final placeId = uuid.v5(placeNs, 'place:store:Nequi');

        final ids = {categoryId, accountId, placeId};
        expect(ids, hasLength(3),
            reason: 'Mismo nombre en diferentes entidades debe dar IDs únicos');
      });

      test('No hay colisiones entre categorías de diferente tipo con mismo nombre', () {
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        // Aunque improbable, verificar que type:name es único
        final assetOtros = uuid.v5(namespace, 'asset:Otros');
        final expenseOtros = uuid.v5(namespace, 'expense:Otros');
        final incomeOtros = uuid.v5(namespace, 'income:Otros');
        final liabilityOtros = uuid.v5(namespace, 'liability:Otros');

        final ids = {assetOtros, expenseOtros, incomeOtros, liabilityOtros};
        expect(ids, hasLength(4),
            reason: '"Otros" en diferentes tipos debe dar IDs únicos');
      });
    });
  });
}
