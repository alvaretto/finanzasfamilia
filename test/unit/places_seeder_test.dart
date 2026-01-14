import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/places_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/places_seeder.dart';
import 'package:finanzas_familiares/data/local/tables/places_table.dart';

/// Tests para verificar que los lugares predefinidos
/// se siembran correctamente en la base de datos.
void main() {
  late AppDatabase database;
  late PlacesDao placesDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    placesDao = PlacesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Places Seeder', () {
    test('debe sembrar supermercados colombianos', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final supermarkets =
          await placesDao.getPlacesByType(PlaceType.supermarket);
      expect(supermarkets.length, greaterThanOrEqualTo(8));

      final names = supermarkets.map((p) => p.name).toSet();
      expect(names, contains('D1'));
      expect(names, contains('Éxito'));
      expect(names, contains('Ara'));
      expect(names, contains('Jumbo'));
      expect(names, contains('Olímpica'));
      expect(names, contains('Carulla'));
    });

    test('debe sembrar tiendas locales', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final stores = await placesDao.getPlacesByType(PlaceType.store);
      expect(stores.length, greaterThanOrEqualTo(4));

      final names = stores.map((p) => p.name).toSet();
      expect(names, contains('Tienda de Barrio'));
      expect(names, contains('Papelería'));
      expect(names, contains('Ferretería'));
      expect(names, contains('Droguería'));
    });

    test('debe sembrar lugares de venta callejera', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final streetPlaces = await placesDao.getPlacesByType(PlaceType.street);
      expect(streetPlaces.length, greaterThanOrEqualTo(3));

      final names = streetPlaces.map((p) => p.name).toSet();
      expect(names, contains('Plaza de Mercado'));
      expect(names, contains('Vendedor Ambulante'));
      expect(names, contains('Galería'));
    });

    test('debe sembrar sitios web/online', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final webPlaces = await placesDao.getPlacesByType(PlaceType.web);
      expect(webPlaces.length, greaterThanOrEqualTo(5));

      final names = webPlaces.map((p) => p.name).toSet();
      expect(names, contains('MercadoLibre'));
      expect(names, contains('Amazon'));
      expect(names, contains('Rappi'));
    });

    test('debe sembrar restaurantes y lugares de comida', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final restaurants =
          await placesDao.getPlacesByType(PlaceType.restaurant);
      expect(restaurants.length, greaterThanOrEqualTo(5));

      final names = restaurants.map((p) => p.name).toSet();
      expect(names, contains('Restaurante Local'));
      expect(names, contains('Corrientazo'));
      expect(names, contains('Panadería'));
      expect(names, contains('Cafetería'));
    });

    test('debe sembrar farmacias', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final pharmacies = await placesDao.getPlacesByType(PlaceType.pharmacy);
      expect(pharmacies.length, greaterThanOrEqualTo(4));

      final names = pharmacies.map((p) => p.name).toSet();
      expect(names, contains('Drogas La Rebaja'));
      expect(names, contains('Cruz Verde'));
      expect(names, contains('Colsubsidio'));
    });

    test('debe sembrar estaciones de servicio', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final gasStations =
          await placesDao.getPlacesByType(PlaceType.gasStation);
      expect(gasStations.length, greaterThanOrEqualTo(4));

      final names = gasStations.map((p) => p.name).toSet();
      expect(names, contains('Terpel'));
      expect(names, contains('Texaco'));
      expect(names, contains('Mobil'));
    });

    test('debe sembrar centros comerciales', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final malls = await placesDao.getPlacesByType(PlaceType.mall);
      expect(malls.length, greaterThanOrEqualTo(3));

      final names = malls.map((p) => p.name).toSet();
      expect(names, contains('Centro Comercial'));
      expect(names, contains('Alkosto'));
      expect(names, contains('Homecenter'));
    });

    test('debe marcar todos los lugares como sistema', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final allPlaces = await placesDao.getAllPlaces();
      for (final place in allPlaces) {
        expect(place.isSystem, isTrue,
            reason: 'Lugar ${place.name} debe ser isSystem=true');
      }
    });

    test('no debe sembrar duplicados si ya existen lugares', () async {
      // Arrange - Sembrar primero
      await seedPlaces(placesDao);
      final countBefore = (await placesDao.getAllPlaces()).length;

      // Act - Intentar sembrar de nuevo
      await seedPlaces(placesDao);
      final countAfter = (await placesDao.getAllPlaces()).length;

      // Assert - No deben haber cambiado
      expect(countAfter, equals(countBefore));
    });

    test('debe tener contadores de uso iniciales asignados', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final allPlaces = await placesDao.getAllPlaces();

      // Tienda de Barrio debe tener alto uso
      final tienda =
          allPlaces.firstWhere((p) => p.name == 'Tienda de Barrio');
      expect(tienda.usageCount, greaterThan(100));

      // D1 debe tener alto uso (popular en Colombia)
      final d1 = allPlaces.firstWhere((p) => p.name == 'D1');
      expect(d1.usageCount, greaterThanOrEqualTo(100));
    });

    test('debe ordenar lugares por uso descendente', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final mostUsed = await placesDao.getMostUsedPlaces(limit: 5);
      expect(mostUsed.length, equals(5));

      // Verificar que están ordenados por uso
      for (int i = 0; i < mostUsed.length - 1; i++) {
        expect(mostUsed[i].usageCount ?? 0,
            greaterThanOrEqualTo(mostUsed[i + 1].usageCount ?? 0));
      }
    });

    test('debe tener notas descriptivas en los lugares', () async {
      // Arrange & Act
      await seedPlaces(placesDao);

      // Assert
      final allPlaces = await placesDao.getAllPlaces();

      final d1 = allPlaces.firstWhere((p) => p.name == 'D1');
      expect(d1.notes, isNotNull);
      expect(d1.notes, contains('descuento'));

      final rappi = allPlaces.firstWhere((p) => p.name == 'Rappi');
      expect(rappi.notes, isNotNull);
      expect(rappi.notes!.toLowerCase(), contains('delivery'));
    });

    test('debe buscar lugares por nombre', () async {
      // Arrange
      await seedPlaces(placesDao);

      // Act
      final results = await placesDao.searchByName('Éxito');

      // Assert
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.first.name, contains('Éxito'));
    });
  });
}
