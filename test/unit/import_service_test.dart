import 'dart:io';

import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/import_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para el ImportService
/// Importa datos desde CSV y Excel con validación
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late TransactionsDao transactionsDao;
  late ImportService importService;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
    transactionsDao = TransactionsDao(database);
    importService = ImportService(
      db: database,
      categoriesDao: categoriesDao,
      transactionsDao: transactionsDao,
    );

    tempDir = await Directory.systemTemp.createTemp('import_test_');

    // Sembrar categorías para validación de referencias
    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImportService - Validación CSV', () {
    test('valida CSV con headers correctos', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final csvPath = '${tempDir.path}/valid.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        'tx-001,expense,50000,Compra mercado,${expenseCategory.id},2024-06-15\n',
      );

      // Act
      final result = await importService.validateCsvFile(csvPath);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('detecta headers faltantes en CSV', () async {
      // Arrange - CSV sin header de amount
      final csvPath = '${tempDir.path}/invalid_headers.csv';
      await File(csvPath).writeAsString(
        'id,type,description,categoryId,date\n'
        'tx-001,expense,Compra,cat-mercado,2024-06-15\n',
      );

      // Act
      final result = await importService.validateCsvFile(csvPath);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('amount')), isTrue);
    });

    test('detecta valores vacíos requeridos', () async {
      // Arrange
      final csvPath = '${tempDir.path}/empty_values.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        ',expense,50000,Compra,cat-mercado,2024-06-15\n', // id vacío
      );

      // Act
      final result = await importService.validateCsvFile(csvPath);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('id')), isTrue);
    });

    test('detecta formato de fecha inválido', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final csvPath = '${tempDir.path}/invalid_date.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        'tx-001,expense,50000,Compra,${expenseCategory.id},15/06/2024\n', // Formato incorrecto
      );

      // Act
      final result = await importService.validateCsvFile(csvPath);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.toLowerCase().contains('fecha')), isTrue);
    });
  });

  group('ImportService - Import CSV', () {
    test('importa transacciones desde CSV válido', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final csvPath = '${tempDir.path}/transactions.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        'tx-import-001,expense,75000,Compra supermercado,${expenseCategory.id},2024-06-15\n'
        'tx-import-002,expense,25000,Transporte,${expenseCategory.id},2024-06-16\n',
      );

      // Act
      final result = await importService.importTransactionsFromCsv(csvPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.importedCount, equals(2));
      expect(result.errors, isEmpty);
    });

    test('reporta errores de filas individuales sin fallar todo', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final csvPath = '${tempDir.path}/mixed.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        'tx-mix-001,expense,50000,Válido,${expenseCategory.id},2024-06-15\n'
        'tx-mix-002,expense,-1000,Inválido,${expenseCategory.id},2024-06-16\n' // Monto negativo
        'tx-mix-003,expense,30000,Válido2,${expenseCategory.id},2024-06-17\n',
      );

      // Act
      final result = await importService.importTransactionsFromCsv(csvPath);

      // Assert
      expect(result.success, isTrue); // Parcialmente exitoso
      expect(result.importedCount, equals(2)); // Solo 2 válidas
      expect(result.skippedCount, equals(1)); // 1 saltada
      expect(result.errors.length, equals(1));
    });
  });

  group('ImportService - Import Excel', () {
    test('importa transacciones desde Excel', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final excel = Excel.createExcel();
      final sheet = excel['Transacciones'];

      // Headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('id');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('type');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('amount');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('description');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('categoryId');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('date');

      // Data
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('tx-excel-001');
      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue('expense');
      sheet.cell(CellIndex.indexByString('C2')).value = const DoubleCellValue(100000);
      sheet.cell(CellIndex.indexByString('D2')).value = TextCellValue('Compra Excel');
      sheet.cell(CellIndex.indexByString('E2')).value = TextCellValue(expenseCategory.id);
      sheet.cell(CellIndex.indexByString('F2')).value = TextCellValue('2024-06-20');

      excel.delete('Sheet1');

      final excelPath = '${tempDir.path}/import.xlsx';
      await File(excelPath).writeAsBytes(excel.encode()!);

      // Act
      final result = await importService.importTransactionsFromExcel(
        excelPath,
        sheetName: 'Transacciones',
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.importedCount, equals(1));
    });
  });

  group('ImportService - Validación de Referencias', () {
    test('valida que categoryId existe en catálogo', () async {
      // Arrange
      final csvPath = '${tempDir.path}/invalid_ref.csv';
      await File(csvPath).writeAsString(
        'id,type,amount,description,categoryId,date\n'
        'tx-ref-001,expense,50000,Compra,CATEGORIA-INEXISTENTE,2024-06-15\n',
      );

      // Act
      final result = await importService.validateCsvFile(csvPath);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('categoría')), isTrue);
    });
  });

  group('ImportService - Modo Preview', () {
    test('preview muestra datos sin importar', () async {
      // Arrange
      final allCategories = await categoriesDao.getAllCategories();
      final expenseCategory = allCategories.firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      final csvPath = '${tempDir.path}/preview.csv';
      // CSV sin BOM y con formato correcto
      final csvContent = 'id,type,amount,description,categoryId,date\n'
          'tx-preview-001,expense,50000,Preview,${expenseCategory.id},2024-06-15';
      await File(csvPath).writeAsString(csvContent);

      // Act
      final preview = await importService.previewCsvImport(csvPath, limit: 10);

      // Assert
      expect(preview.totalRows, equals(1));
      expect(preview.rows.length, equals(1));
      expect(preview.rows.first['id'], equals('tx-preview-001'));

      // Verificar que no se importó realmente
      final transactions = await transactionsDao.getAllTransactions();
      expect(transactions.where((t) => t.id == 'tx-preview-001'), isEmpty);
    });
  });
}
