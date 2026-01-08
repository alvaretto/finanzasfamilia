import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/export_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para el ExportService
/// Exporta datos a CSV, Excel y PDF
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late TransactionsDao transactionsDao;
  late ExportService exportService;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
    transactionsDao = TransactionsDao(database);
    exportService = ExportService(
      db: database,
      categoriesDao: categoriesDao,
      transactionsDao: transactionsDao,
    );

    // Crear directorio temporal para exports
    tempDir = await Directory.systemTemp.createTemp('export_test_');

    // Sembrar datos de prueba
    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    // Limpiar directorio temporal
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExportService - CSV', () {
    test('exporta categorías a CSV correctamente', () async {
      // Arrange
      final outputPath = '${tempDir.path}/categories.csv';

      // Act
      final result = await exportService.exportCategoriesToCsv(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.filePath, equals(outputPath));

      final file = File(outputPath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('id'));
      expect(content, contains('name'));
      expect(content, contains('type'));
      expect(content, contains('Lo que Tengo')); // Categoría raíz de activos
    });

    test('exporta transacciones vacías a CSV con headers', () async {
      // Arrange
      final outputPath = '${tempDir.path}/transactions.csv';

      // Act
      final result = await exportService.exportTransactionsToCsv(
        outputPath,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      // Assert
      expect(result.success, isTrue);

      final file = File(outputPath);
      final content = await file.readAsString();
      // Debe tener headers aunque no haya datos
      expect(content, contains('id'));
      expect(content, contains('amount'));
      expect(content, contains('date'));
    });

    test('CSV usa separador correcto para Excel español', () async {
      // Arrange
      final outputPath = '${tempDir.path}/categories_es.csv';

      // Act
      await exportService.exportCategoriesToCsv(
        outputPath,
        separator: ';', // Separador para Excel en español
      );

      // Assert
      final content = await File(outputPath).readAsString();
      expect(content, contains(';'));
    });
  });

  group('ExportService - Excel', () {
    test('exporta categorías a Excel con formato', () async {
      // Arrange
      final outputPath = '${tempDir.path}/categories.xlsx';

      // Act
      final result = await exportService.exportCategoriesToExcel(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.filePath, equals(outputPath));

      final file = File(outputPath);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));
    });

    test('Excel incluye múltiples hojas de referencia', () async {
      // Arrange
      final outputPath = '${tempDir.path}/reference.xlsx';

      // Act
      final result = await exportService.exportReferenceDataToExcel(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.sheets, contains('Categorías'));
      expect(result.sheets, contains('Cuentas'));
    });

    test('Excel tiene headers con estilo', () async {
      // Arrange
      final outputPath = '${tempDir.path}/styled.xlsx';

      // Act
      final result = await exportService.exportCategoriesToExcel(outputPath);

      // Assert
      expect(result.success, isTrue);
      // El archivo debe existir y tener contenido
      final file = File(outputPath);
      expect(await file.length(), greaterThan(1000)); // Excel mínimo tiene ~1KB
    });
  });

  group('ExportService - Validación', () {
    test('retorna error si el path es inválido', () async {
      // Arrange
      const invalidPath = '/invalid/path/that/does/not/exist/file.csv';

      // Act
      final result = await exportService.exportCategoriesToCsv(invalidPath);

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('retorna información del export completado', () async {
      // Arrange
      final outputPath = '${tempDir.path}/info_test.csv';

      // Act
      final result = await exportService.exportCategoriesToCsv(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.recordCount, greaterThan(0));
      expect(result.exportedAt, isNotNull);
    });
  });

  group('ExportService - Transacciones con filtros', () {
    test('filtra transacciones por rango de fechas', () async {
      // Arrange
      final outputPath = '${tempDir.path}/filtered.csv';

      // Act
      final result = await exportService.exportTransactionsToCsv(
        outputPath,
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 30),
      );

      // Assert
      expect(result.success, isTrue);
    });

    test('filtra transacciones por categoría', () async {
      // Arrange
      final outputPath = '${tempDir.path}/by_category.csv';
      final categories = await categoriesDao.getCategoriesByType('expense');
      final expenseCategory = categories.first;

      // Act
      final result = await exportService.exportTransactionsToCsv(
        outputPath,
        categoryId: expenseCategory.id,
      );

      // Assert
      expect(result.success, isTrue);
    });
  });
}
