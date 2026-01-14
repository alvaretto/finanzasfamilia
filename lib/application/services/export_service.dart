import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/daos.dart';

/// Resultado de una operación de exportación
class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int recordCount;
  final DateTime? exportedAt;
  final List<String> sheets;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.recordCount = 0,
    this.exportedAt,
    this.sheets = const [],
  });

  factory ExportResult.success({
    required String filePath,
    required int recordCount,
    List<String> sheets = const [],
  }) {
    return ExportResult(
      success: true,
      filePath: filePath,
      recordCount: recordCount,
      exportedAt: DateTime.now(),
      sheets: sheets,
    );
  }

  factory ExportResult.failure(String errorMessage) {
    return ExportResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Servicio de Exportación de Datos
///
/// Exporta datos a CSV, Excel y PDF
class ExportService {
  final AppDatabase db;
  final CategoriesDao categoriesDao;
  final TransactionsDao transactionsDao;

  ExportService({
    required this.db,
    required this.categoriesDao,
    required this.transactionsDao,
  });

  // ============================================================
  // CSV Exports
  // ============================================================

  /// Exporta categorías a CSV
  Future<ExportResult> exportCategoriesToCsv(
    String outputPath, {
    String separator = ',',
  }) async {
    try {
      final categories = await categoriesDao.getAllCategories();
      final rows = _categoriesToRows(categories);
      return _writeCsvFile(outputPath, rows, separator);
    } catch (e) {
      return ExportResult.failure('Error exportando categorías: $e');
    }
  }

  /// Exporta transacciones a CSV con filtros opcionales
  Future<ExportResult> exportTransactionsToCsv(
    String outputPath, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String separator = ',',
  }) async {
    try {
      final transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      final rows = _transactionsToRows(transactions);
      return _writeCsvFile(outputPath, rows, separator);
    } catch (e) {
      return ExportResult.failure('Error exportando transacciones: $e');
    }
  }

  // ============================================================
  // Excel Exports
  // ============================================================

  /// Exporta categorías a Excel
  Future<ExportResult> exportCategoriesToExcel(String outputPath) async {
    try {
      final categories = await categoriesDao.getAllCategories();
      final excel = Excel.createExcel();

      _addCategoriesSheet(excel, categories);
      excel.delete('Sheet1'); // Eliminar hoja por defecto

      return _writeExcelFile(outputPath, excel, categories.length, ['Categorías']);
    } catch (e) {
      return ExportResult.failure('Error exportando a Excel: $e');
    }
  }

  /// Exporta datos de referencia a Excel (múltiples hojas)
  Future<ExportResult> exportReferenceDataToExcel(String outputPath) async {
    try {
      final excel = Excel.createExcel();
      final sheets = <String>[];
      var totalRecords = 0;

      // Hoja de Categorías
      final categories = await categoriesDao.getAllCategories();
      _addCategoriesSheet(excel, categories);
      sheets.add('Categorías');
      totalRecords += categories.length;

      // Hoja de Cuentas
      final accounts = await _getAllAccounts();
      _addAccountsSheet(excel, accounts);
      sheets.add('Cuentas');
      totalRecords += accounts.length;

      excel.delete('Sheet1');

      return _writeExcelFile(outputPath, excel, totalRecords, sheets);
    } catch (e) {
      return ExportResult.failure('Error exportando datos de referencia: $e');
    }
  }

  // ============================================================
  // Private Helpers - Data Conversion
  // ============================================================

  List<List<dynamic>> _categoriesToRows(List<CategoryEntry> categories) {
    final headers = ['id', 'name', 'type', 'parentId', 'level', 'icon', 'isActive', 'isSystem'];
    final rows = <List<dynamic>>[headers];

    for (final cat in categories) {
      rows.add([
        cat.id,
        cat.name,
        cat.type,
        cat.parentId ?? '',
        cat.level,
        cat.icon ?? '',
        cat.isActive,
        cat.isSystem,
      ]);
    }

    return rows;
  }

  List<List<dynamic>> _transactionsToRows(List<TransactionEntry> transactions) {
    final headers = [
      'id',
      'type',
      'amount',
      'description',
      'categoryId',
      'fromAccountId',
      'toAccountId',
      'date',
      'createdAt',
    ];
    final rows = <List<dynamic>>[headers];

    for (final tx in transactions) {
      rows.add([
        tx.id,
        tx.type,
        tx.amount,
        tx.description ?? '',
        tx.categoryId,
        tx.fromAccountId ?? '',
        tx.toAccountId ?? '',
        tx.transactionDate.toIso8601String(),
        (tx.createdAt ?? DateTime.now()).toIso8601String(),
      ]);
    }

    return rows;
  }

  // ============================================================
  // Private Helpers - File Writing
  // ============================================================

  Future<ExportResult> _writeCsvFile(
    String outputPath,
    List<List<dynamic>> rows,
    String separator,
  ) async {
    try {
      final csvData = const ListToCsvConverter().convert(
        rows,
        fieldDelimiter: separator,
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(csvData);

      return ExportResult.success(
        filePath: outputPath,
        recordCount: rows.length - 1, // Excluir header
      );
    } catch (e) {
      return ExportResult.failure('Error escribiendo CSV: $e');
    }
  }

  Future<ExportResult> _writeExcelFile(
    String outputPath,
    Excel excel,
    int recordCount,
    List<String> sheets,
  ) async {
    try {
      final file = File(outputPath);
      await file.parent.create(recursive: true);

      final bytes = excel.encode();
      if (bytes == null) {
        return ExportResult.failure('Error codificando Excel');
      }

      await file.writeAsBytes(bytes);

      return ExportResult.success(
        filePath: outputPath,
        recordCount: recordCount,
        sheets: sheets,
      );
    } catch (e) {
      return ExportResult.failure('Error escribiendo Excel: $e');
    }
  }

  // ============================================================
  // Private Helpers - Excel Sheets
  // ============================================================

  void _addCategoriesSheet(Excel excel, List<CategoryEntry> categories) {
    final sheet = excel['Categorías'];
    final headers = ['ID', 'Nombre', 'Tipo', 'Padre', 'Nivel', 'Icono', 'Activo', 'Sistema'];

    // Headers con estilo
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Datos
    for (var row = 0; row < categories.length; row++) {
      final cat = categories[row];
      _setCellValues(sheet, row + 1, [
        cat.id,
        cat.name,
        _translateType(cat.type),
        cat.parentId ?? '',
        (cat.level ?? 0).toString(),
        cat.icon ?? '',
        (cat.isActive ?? true) ? 'Sí' : 'No',
        (cat.isSystem ?? false) ? 'Sí' : 'No',
      ]);
    }
  }

  void _addAccountsSheet(Excel excel, List<AccountEntry> accounts) {
    final sheet = excel['Cuentas'];
    final headers = ['ID', 'Nombre', 'Categoría', 'Saldo', 'Activa'];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    for (var row = 0; row < accounts.length; row++) {
      final acc = accounts[row];
      _setCellValues(sheet, row + 1, [
        acc.id,
        acc.name,
        acc.categoryId,
        (acc.balance ?? 0.0).toString(),
        (acc.isActive ?? true) ? 'Sí' : 'No',
      ]);
    }
  }

  void _setCellValues(Sheet sheet, int rowIndex, List<String> values) {
    for (var col = 0; col < values.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
          .value = TextCellValue(values[col]);
    }
  }

  String _translateType(String type) {
    switch (type) {
      case 'asset':
        return 'Activo';
      case 'liability':
        return 'Pasivo';
      case 'income':
        return 'Ingreso';
      case 'expense':
        return 'Gasto';
      default:
        return type;
    }
  }

  // ============================================================
  // Private Helpers - Data Fetching
  // ============================================================

  Future<List<TransactionEntry>> _getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);

    if (startDate != null || endDate != null || categoryId != null) {
      query.where((t) {
        Expression<bool> condition = const Constant(true);

        if (startDate != null) {
          condition = condition & t.transactionDate.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          condition = condition & t.transactionDate.isSmallerOrEqualValue(endDate);
        }
        if (categoryId != null) {
          condition = condition & t.categoryId.equals(categoryId);
        }

        return condition;
      });
    }

    return query.get();
  }

  Future<List<AccountEntry>> _getAllAccounts() async {
    return (db.select(db.accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();
  }
}
