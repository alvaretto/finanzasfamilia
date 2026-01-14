import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/daos.dart';

/// Resultado de validación de archivo
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() => ValidationResult(isValid: true);

  factory ValidationResult.invalid(List<String> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// Resultado de operación de importación
class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;
  final DateTime? importedAt;

  ImportResult({
    required this.success,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
    this.importedAt,
  });

  factory ImportResult.success({
    required int importedCount,
    int skippedCount = 0,
    List<String> errors = const [],
  }) {
    return ImportResult(
      success: true,
      importedCount: importedCount,
      skippedCount: skippedCount,
      errors: errors,
      importedAt: DateTime.now(),
    );
  }

  factory ImportResult.failure(List<String> errors) {
    return ImportResult(success: false, errors: errors);
  }
}

/// Preview de importación
class ImportPreview {
  final List<Map<String, dynamic>> rows;
  final List<String> headers;
  final int totalRows;

  ImportPreview({
    required this.rows,
    required this.headers,
    required this.totalRows,
  });
}

/// Servicio de Importación de Datos
///
/// Importa datos desde CSV y Excel con validación
class ImportService {
  final AppDatabase db;
  final CategoriesDao categoriesDao;
  final TransactionsDao transactionsDao;

  static const _requiredTransactionHeaders = [
    'id',
    'type',
    'amount',
    'description',
    'categoryId',
    'date',
  ];

  ImportService({
    required this.db,
    required this.categoriesDao,
    required this.transactionsDao,
  });

  // ============================================================
  // Validación
  // ============================================================

  /// Valida un archivo CSV antes de importar
  Future<ValidationResult> validateCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ValidationResult.invalid(['El archivo no existe']);
      }

      final content = await file.readAsString();
      final rows = _parseCsv(content);

      if (rows.isEmpty) {
        return ValidationResult.invalid(['El archivo está vacío']);
      }

      final headers = rows.first.map((h) => h.toString().toLowerCase()).toList();
      final errors = <String>[];

      // Validar headers requeridos
      for (final required in _requiredTransactionHeaders) {
        if (!headers.contains(required.toLowerCase())) {
          errors.add('Falta la columna requerida: $required');
        }
      }

      if (errors.isNotEmpty) {
        return ValidationResult.invalid(errors);
      }

      // Validar cada fila
      final categoryIds = await _getCategoryIds();

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowErrors = await _validateRow(row, headers, i + 1, categoryIds);
        errors.addAll(rowErrors);
      }

      return errors.isEmpty
          ? ValidationResult.valid()
          : ValidationResult.invalid(errors);
    } catch (e) {
      return ValidationResult.invalid(['Error leyendo archivo: $e']);
    }
  }

  // ============================================================
  // Import CSV
  // ============================================================

  /// Importa transacciones desde CSV
  Future<ImportResult> importTransactionsFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final rows = _parseCsv(content);

      if (rows.length < 2) {
        return ImportResult.failure(['El archivo no tiene datos']);
      }

      final headers = rows.first.map((h) => h.toString().toLowerCase()).toList();
      final categoryIds = await _getCategoryIds();

      var importedCount = 0;
      var skippedCount = 0;
      final errors = <String>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowErrors = await _validateRow(row, headers, i + 1, categoryIds);

        if (rowErrors.isNotEmpty) {
          errors.addAll(rowErrors);
          skippedCount++;
          continue;
        }

        try {
          await _importTransactionRow(row, headers);
          importedCount++;
        } catch (e) {
          errors.add('Fila ${i + 1}: Error importando - $e');
          skippedCount++;
        }
      }

      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.failure(['Error importando CSV: $e']);
    }
  }

  // ============================================================
  // Import Excel
  // ============================================================

  /// Importa transacciones desde Excel
  Future<ImportResult> importTransactionsFromExcel(
    String filePath, {
    String sheetName = 'Transacciones',
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel[sheetName];
      if (sheet.maxRows < 2) {
        return ImportResult.failure(['La hoja no tiene datos']);
      }

      final headers = _extractExcelHeaders(sheet);
      final categoryIds = await _getCategoryIds();

      var importedCount = 0;
      var skippedCount = 0;
      final errors = <String>[];

      for (var i = 1; i < sheet.maxRows; i++) {
        final row = _extractExcelRow(sheet, i);
        final rowErrors = await _validateRow(row, headers, i + 1, categoryIds);

        if (rowErrors.isNotEmpty) {
          errors.addAll(rowErrors);
          skippedCount++;
          continue;
        }

        try {
          await _importTransactionRow(row, headers);
          importedCount++;
        } catch (e) {
          errors.add('Fila ${i + 1}: Error importando - $e');
          skippedCount++;
        }
      }

      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.failure(['Error importando Excel: $e']);
    }
  }

  // ============================================================
  // Preview
  // ============================================================

  /// Preview de importación CSV (sin importar)
  Future<ImportPreview> previewCsvImport(String filePath, {int limit = 10}) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = _parseCsv(content);

    if (rows.isEmpty) {
      return ImportPreview(rows: [], headers: [], totalRows: 0);
    }

    final headers = rows.first.map((h) => h.toString()).toList();
    final dataRows = <Map<String, dynamic>>[];

    final maxRows = (rows.length - 1).clamp(0, limit);
    for (var i = 1; i <= maxRows; i++) {
      final row = rows[i];
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j];
      }
      dataRows.add(map);
    }

    return ImportPreview(
      rows: dataRows,
      headers: headers,
      totalRows: rows.length - 1,
    );
  }

  // ============================================================
  // Private Helpers - CSV Parsing
  // ============================================================

  /// Parsea contenido CSV con auto-detección de EOL
  List<List<dynamic>> _parseCsv(String content) {
    // Auto-detectar el terminador de línea
    final eol = content.contains('\r\n') ? '\r\n' : '\n';
    return CsvToListConverter(eol: eol).convert(content);
  }

  // ============================================================
  // Private Helpers - Validation
  // ============================================================

  Future<List<String>> _validateRow(
    List<dynamic> row,
    List<String> headers,
    int rowNumber,
    Set<String> categoryIds,
  ) async {
    final errors = <String>[];

    String? getValue(String header) {
      final index = headers.indexOf(header.toLowerCase());
      if (index < 0 || index >= row.length) return null;
      final value = row[index];
      if (value == null) return null;
      return value.toString().trim();
    }

    // Validar campos requeridos
    final id = getValue('id');
    if (id == null || id.isEmpty) {
      errors.add('Fila $rowNumber: id es requerido');
    }

    final amount = getValue('amount');
    if (amount == null || amount.isEmpty) {
      errors.add('Fila $rowNumber: amount es requerido');
    } else {
      final numAmount = double.tryParse(amount);
      if (numAmount == null || numAmount <= 0) {
        errors.add('Fila $rowNumber: amount debe ser un número positivo');
      }
    }

    final categoryId = getValue('categoryId');
    if (categoryId != null && categoryId.isNotEmpty) {
      if (!categoryIds.contains(categoryId)) {
        errors.add('Fila $rowNumber: categoría "$categoryId" no existe');
      }
    }

    final date = getValue('date');
    if (date != null && date.isNotEmpty) {
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate == null) {
        errors.add('Fila $rowNumber: fecha "$date" tiene formato inválido (use YYYY-MM-DD)');
      }
    }

    return errors;
  }

  Future<Set<String>> _getCategoryIds() async {
    final categories = await categoriesDao.getAllCategories();
    return categories.map((c) => c.id).toSet();
  }

  // ============================================================
  // Private Helpers - Import
  // ============================================================

  Future<void> _importTransactionRow(
    List<dynamic> row,
    List<String> headers,
  ) async {
    String? getValue(String header) {
      final index = headers.indexOf(header.toLowerCase());
      if (index < 0 || index >= row.length) return null;
      final value = row[index];
      if (value == null) return null;
      return value.toString().trim();
    }

    final id = getValue('id')!;
    final type = getValue('type') ?? 'expense';
    final amount = double.parse(getValue('amount')!);
    final description = getValue('description') ?? '';
    final categoryId = getValue('categoryId')!;
    final dateStr = getValue('date')!;
    final date = DateTime.parse(dateStr);

    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      userId = null;
    }
    final companion = TransactionsCompanion.insert(
      id: id,
      userId: Value(userId),
      type: type,
      amount: amount,
      description: Value(description),
      categoryId: categoryId,
      transactionDate: date,
    );

    await transactionsDao.insertTransaction(companion);
  }

  // ============================================================
  // Private Helpers - Excel
  // ============================================================

  List<String> _extractExcelHeaders(Sheet sheet) {
    final headers = <String>[];
    for (var col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      headers.add(cell.value?.toString().toLowerCase() ?? '');
    }
    return headers;
  }

  List<dynamic> _extractExcelRow(Sheet sheet, int rowIndex) {
    final row = <dynamic>[];
    for (var col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      row.add(cell.value);
    }
    return row;
  }
}
