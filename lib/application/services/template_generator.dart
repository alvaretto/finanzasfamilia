import 'dart:io';

import 'package:excel/excel.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/daos.dart';
import 'export_service.dart';

/// Generador de Plantillas Excel para Importación
///
/// Crea archivos Excel con:
/// - Hoja de instrucciones
/// - Hoja de datos con headers y validaciones
/// - Hojas de referencia (categorías, cuentas, unidades)
class TemplateGenerator {
  final AppDatabase db;
  final CategoriesDao categoriesDao;

  TemplateGenerator({
    required this.db,
    required this.categoriesDao,
  });

  /// Genera plantilla para importar transacciones
  Future<ExportResult> generateTransactionsTemplate(
    String outputPath, {
    bool includeExamples = false,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheets = <String>[];

      // 1. Hoja de Instrucciones
      _addInstructionsSheet(excel);
      sheets.add('Instrucciones');

      // 2. Hoja de Datos (Transacciones)
      await _addTransactionsDataSheet(excel, includeExamples);
      sheets.add('Transacciones');

      // 3. Hoja de Categorías (Referencia)
      await _addCategoriesReferenceSheet(excel);
      sheets.add('Categorías');

      // Eliminar hoja por defecto
      excel.delete('Sheet1');

      return _writeExcelFile(outputPath, excel, sheets);
    } catch (e) {
      return ExportResult.failure('Error generando plantilla: $e');
    }
  }

  /// Genera plantilla completa con todas las hojas de referencia
  Future<ExportResult> generateFullTemplate(String outputPath) async {
    try {
      final excel = Excel.createExcel();
      final sheets = <String>[];

      // 1. Hoja de Instrucciones
      _addInstructionsSheet(excel);
      sheets.add('Instrucciones');

      // 2. Hoja de Datos (Transacciones)
      await _addTransactionsDataSheet(excel, true);
      sheets.add('Transacciones');

      // 3. Hoja de Categorías (Referencia)
      await _addCategoriesReferenceSheet(excel);
      sheets.add('Categorías');

      // Eliminar hoja por defecto
      excel.delete('Sheet1');

      return _writeExcelFile(outputPath, excel, sheets);
    } catch (e) {
      return ExportResult.failure('Error generando plantilla: $e');
    }
  }

  // ============================================================
  // Private Helpers - Sheets
  // ============================================================

  void _addInstructionsSheet(Excel excel) {
    final sheet = excel['Instrucciones'];

    final instructions = [
      ['PLANTILLA DE IMPORTACIÓN DE TRANSACCIONES'],
      [''],
      ['INSTRUCCIONES:'],
      ['1. Complete los datos en la hoja "Transacciones"'],
      ['2. Los campos marcados con (*) son obligatorios'],
      ['3. Use los IDs de la hoja "Categorías" para el campo categoryId'],
      ['4. El formato de fecha debe ser YYYY-MM-DD (ej: 2024-06-15)'],
      ['5. Los montos deben ser números positivos sin símbolos de moneda'],
      [''],
      ['CAMPOS REQUERIDOS:'],
      ['- id: Identificador único de la transacción (*)'],
      ['- type: Tipo (expense, income, transfer) (*)'],
      ['- amount: Monto de la transacción (*)'],
      ['- categoryId: ID de la categoría (*)'],
      ['- date: Fecha en formato YYYY-MM-DD (*)'],
      ['- description: Descripción opcional'],
      [''],
      ['TIPOS DE TRANSACCIÓN:'],
      ['- expense: Gasto'],
      ['- income: Ingreso'],
      ['- transfer: Transferencia entre cuentas'],
      [''],
      ['NOTAS:'],
      ['- No modifique la estructura de las columnas'],
      ['- Puede agregar tantas filas como necesite'],
      ['- Revise la hoja "Categorías" para obtener los IDs válidos'],
    ];

    for (var row = 0; row < instructions.length; row++) {
      final content = instructions[row];
      if (content.isNotEmpty) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        cell.value = TextCellValue(content[0]);

        // Estilo para título
        if (row == 0) {
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 14,
          );
        } else if (content[0].endsWith(':') && !content[0].startsWith('-')) {
          cell.cellStyle = CellStyle(bold: true);
        }
      }
    }
  }

  Future<void> _addTransactionsDataSheet(Excel excel, bool includeExamples) async {
    final sheet = excel['Transacciones'];

    // Headers
    final headers = ['id', 'type', 'amount', 'description', 'categoryId', 'date'];

    // Estilo de headers
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Datos de ejemplo (si se solicitan)
    if (includeExamples) {
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && (c.level ?? 0) > 0,
        orElse: () => categories.first,
      );

      final examples = [
        ['tx-ejemplo-001', 'expense', '50000', 'Compra supermercado', expenseCategory.id, '2024-06-15'],
        ['tx-ejemplo-002', 'expense', '25000', 'Transporte', expenseCategory.id, '2024-06-16'],
      ];

      for (var row = 0; row < examples.length; row++) {
        final example = examples[row];
        for (var col = 0; col < example.length; col++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
              .value = TextCellValue(example[col]);
        }
      }
    }
  }

  Future<void> _addCategoriesReferenceSheet(Excel excel) async {
    final sheet = excel['Categorías'];

    // Headers
    final headers = ['ID', 'Nombre', 'Tipo', 'Nivel'];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#70AD47'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Datos de categorías
    final categories = await categoriesDao.getAllCategories();

    for (var row = 0; row < categories.length; row++) {
      final cat = categories[row];
      final values = [
        cat.id,
        cat.name,
        _translateType(cat.type),
        cat.level.toString(),
      ];

      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = TextCellValue(values[col]);
      }
    }
  }

  // ============================================================
  // Private Helpers - Utilities
  // ============================================================

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

  Future<ExportResult> _writeExcelFile(
    String outputPath,
    Excel excel,
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
        recordCount: 0,
        sheets: sheets,
      );
    } catch (e) {
      return ExportResult.failure('Error escribiendo archivo: $e');
    }
  }
}
