import 'dart:io';

import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/template_generator.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para el TemplateGenerator
/// Genera plantillas Excel para importación de datos
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late TemplateGenerator templateGenerator;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
    templateGenerator = TemplateGenerator(
      db: database,
      categoriesDao: categoriesDao,
    );

    tempDir = await Directory.systemTemp.createTemp('template_test_');

    // Sembrar datos de referencia
    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TemplateGenerator - Plantilla de Transacciones', () {
    test('genera plantilla Excel con estructura correcta', () async {
      // Arrange
      final outputPath = '${tempDir.path}/template_transactions.xlsx';

      // Act
      final result = await templateGenerator.generateTransactionsTemplate(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.filePath, equals(outputPath));

      final file = File(outputPath);
      expect(await file.exists(), isTrue);
    });

    test('plantilla incluye hoja de instrucciones', () async {
      // Arrange
      final outputPath = '${tempDir.path}/with_instructions.xlsx';

      // Act
      await templateGenerator.generateTransactionsTemplate(outputPath);

      // Assert
      final bytes = await File(outputPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.keys, contains('Instrucciones'));
    });

    test('plantilla incluye hoja de datos con headers', () async {
      // Arrange
      final outputPath = '${tempDir.path}/with_data.xlsx';

      // Act
      await templateGenerator.generateTransactionsTemplate(outputPath);

      // Assert
      final bytes = await File(outputPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.keys, contains('Transacciones'));

      final dataSheet = excel['Transacciones'];
      // Verificar headers en primera fila
      final headers = <String>[];
      for (var col = 0; col < dataSheet.maxColumns; col++) {
        final cell = dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        if (cell.value != null) {
          headers.add(cell.value.toString().toLowerCase());
        }
      }

      expect(headers, contains('id'));
      expect(headers, contains('type'));
      expect(headers, contains('amount'));
      expect(headers, contains('categoryid'));
    });

    test('plantilla incluye hoja de categorías de referencia', () async {
      // Arrange
      final outputPath = '${tempDir.path}/with_categories.xlsx';

      // Act
      await templateGenerator.generateTransactionsTemplate(outputPath);

      // Assert
      final bytes = await File(outputPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.keys, contains('Categorías'));

      final categoriesSheet = excel['Categorías'];
      // Debe tener datos (no solo headers)
      expect(categoriesSheet.maxRows, greaterThan(1));
    });

    test('hoja de instrucciones tiene contenido', () async {
      // Arrange
      final outputPath = '${tempDir.path}/instructions.xlsx';

      // Act
      await templateGenerator.generateTransactionsTemplate(outputPath);

      // Assert
      final bytes = await File(outputPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final instructionsSheet = excel['Instrucciones'];

      // Debe tener contenido
      expect(instructionsSheet.maxRows, greaterThan(0));

      // Primera celda debe tener título
      final firstCell = instructionsSheet.cell(CellIndex.indexByString('A1'));
      expect(firstCell.value, isNotNull);
    });
  });

  group('TemplateGenerator - Plantilla Completa', () {
    test('genera plantilla completa con todas las hojas', () async {
      // Arrange
      final outputPath = '${tempDir.path}/full_template.xlsx';

      // Act
      final result = await templateGenerator.generateFullTemplate(outputPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.sheets.length, greaterThanOrEqualTo(3));
      expect(result.sheets, contains('Instrucciones'));
      expect(result.sheets, contains('Transacciones'));
      expect(result.sheets, contains('Categorías'));
    });
  });

  group('TemplateGenerator - Datos de Ejemplo', () {
    test('puede incluir filas de ejemplo', () async {
      // Arrange
      final outputPath = '${tempDir.path}/with_examples.xlsx';

      // Act
      await templateGenerator.generateTransactionsTemplate(
        outputPath,
        includeExamples: true,
      );

      // Assert
      final bytes = await File(outputPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final dataSheet = excel['Transacciones'];
      // Debe tener más de 1 fila (header + ejemplos)
      expect(dataSheet.maxRows, greaterThan(1));
    });
  });
}
