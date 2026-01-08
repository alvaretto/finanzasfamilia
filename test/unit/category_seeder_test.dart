import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/category_seeder.dart';

/// Tests para verificar que la jerarquía de categorías del Mermaid
/// se siembra correctamente en la base de datos.
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;

  setUp(() {
    // Base de datos en memoria para tests
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Category Seeder', () {
    test('debe sembrar las 4 categorías raíz principales', () async {
      // Arrange - Ejecutar el seeder
      await seedCategories(categoriesDao);

      // Act
      final rootCategories = await categoriesDao.getRootCategories();

      // Assert - Deben existir las 4 ramas principales
      expect(rootCategories.length, equals(4));

      final rootNames = rootCategories.map((c) => c.name).toSet();
      expect(rootNames, contains('Lo que Tengo')); // Activos
      expect(rootNames, contains('Lo que Debo')); // Pasivos
      expect(rootNames, contains('Dinero que Entra')); // Ingresos
      expect(rootNames, contains('Dinero que Sale')); // Gastos
    });

    test('debe sembrar subcategorías de Activos (Lo que Tengo)', () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act
      final assetCategories = await categoriesDao.getCategoriesByType('asset');
      final rootAsset = assetCategories.firstWhere((c) => c.parentId == null);
      final assetChildren = await categoriesDao.getChildCategories(rootAsset.id);

      // Assert - Deben existir: Efectivo, Bancos, Inversiones
      expect(assetChildren.length, greaterThanOrEqualTo(3));

      final childNames = assetChildren.map((c) => c.name).toSet();
      expect(childNames, contains('Efectivo'));
      expect(childNames, contains('Bancos'));
      expect(childNames, contains('Inversiones'));
    });

    test('debe sembrar subcategorías de Gastos con granularidad', () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act
      final expenseCategories =
          await categoriesDao.getCategoriesByType('expense');
      final rootExpense =
          expenseCategories.firstWhere((c) => c.parentId == null);
      final expenseChildren =
          await categoriesDao.getChildCategories(rootExpense.id);

      // Assert - Deben existir las 9 categorías maestras de gastos
      expect(expenseChildren.length, greaterThanOrEqualTo(9));

      final childNames = expenseChildren.map((c) => c.name).toSet();
      expect(childNames, contains('Impuestos'));
      expect(childNames, contains('Servicios Públicos/Privados'));
      expect(childNames, contains('Alimentación'));
      expect(childNames, contains('Transporte'));
      expect(childNames, contains('Entretenimiento'));
      expect(childNames, contains('Salud'));
      expect(childNames, contains('Educación'));
      expect(childNames, contains('Aseo'));
      expect(childNames, contains('Otros Gastos'));
    });

    test('debe sembrar subcategorías granulares de Alimentación -> Mercado',
        () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act - Buscar Alimentación -> Mercado -> subcategorías
      final allCategories = await categoriesDao.getAllCategories();

      final alimentacion =
          allCategories.firstWhere((c) => c.name == 'Alimentación');
      final alimentacionChildren =
          await categoriesDao.getChildCategories(alimentacion.id);

      final mercado =
          alimentacionChildren.firstWhere((c) => c.name == 'Mercado');
      final mercadoChildren =
          await categoriesDao.getChildCategories(mercado.id);

      // Assert - Mercado debe tener subcategorías granulares
      expect(mercadoChildren.length, greaterThanOrEqualTo(10));

      final mercadoNames = mercadoChildren.map((c) => c.name).toSet();
      expect(mercadoNames, contains('Frutas'));
      expect(mercadoNames, contains('Verduras'));
      expect(mercadoNames, contains('Cárnicos'));
      expect(mercadoNames, contains('Lácteos'));
      expect(mercadoNames, contains('Mecato'));
    });

    test('debe marcar categorías del sistema como isSystem=true', () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act
      final allCategories = await categoriesDao.getAllCategories();

      // Assert - Todas las categorías sembradas deben ser del sistema
      for (final category in allCategories) {
        expect(category.isSystem, isTrue,
            reason: 'Categoría ${category.name} debe ser isSystem=true');
      }
    });

    test('debe asignar iconos emoji a categorías principales', () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act
      final rootCategories = await categoriesDao.getRootCategories();

      // Assert - Las raíces deben tener iconos
      for (final category in rootCategories) {
        expect(category.icon, isNotNull,
            reason: 'Categoría ${category.name} debe tener icono');
        expect(category.icon, isNotEmpty);
      }
    });

    test('debe asignar niveles jerárquicos correctos', () async {
      // Arrange
      await seedCategories(categoriesDao);

      // Act
      final allCategories = await categoriesDao.getAllCategories();

      // Assert
      // Nivel 0: Raíces (Lo que Tengo, Lo que Debo, etc.)
      final level0 = allCategories.where((c) => c.level == 0);
      expect(level0.length, equals(4));

      // Nivel 1: Hijos directos (Efectivo, Bancos, Impuestos, etc.)
      final level1 = allCategories.where((c) => c.level == 1);
      expect(level1.length, greaterThan(10));

      // Nivel 2: Nietos (Frutas, Verduras, etc.)
      final level2 = allCategories.where((c) => c.level == 2);
      expect(level2.length, greaterThan(5));
    });
  });
}

// seedCategories ahora se importa de category_seeder.dart
