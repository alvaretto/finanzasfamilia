import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../features/transactions/domain/models/transaction_model.dart';
import '../../features/accounts/domain/models/account_model.dart';

/// Servicio de exportacion de datos
class ExportService {
  static final ExportService _instance = ExportService._();
  static ExportService get instance => _instance;

  ExportService._();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  /// Exportar transacciones a CSV
  Future<File> exportTransactionsToCSV(
    List<TransactionModel> transactions, {
    String? fileName,
  }) async {
    final List<List<dynamic>> rows = [
      // Header
      [
        'Fecha',
        'Tipo',
        'Categoria',
        'Descripcion',
        'Monto',
        'Cuenta',
        'Notas',
      ],
    ];

    // Data rows
    for (final tx in transactions) {
      rows.add([
        _dateFormat.format(tx.date),
        tx.type.displayName,
        tx.categoryName ?? 'Sin categoria',
        tx.description ?? '',
        tx.amount,
        tx.accountName ?? '',
        tx.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/${fileName ?? 'transacciones_${DateTime.now().millisecondsSinceEpoch}'}.csv',
    );
    await file.writeAsString(csv);

    return file;
  }

  /// Exportar transacciones a PDF
  Future<File> exportTransactionsToPDF(
    List<TransactionModel> transactions, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? fileName,
  }) async {
    final pdf = pw.Document();

    // Calcular totales
    double totalIncome = 0;
    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(
          title: title ?? 'Reporte de Transacciones',
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Resumen
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Ingresos',
                  _currencyFormat.format(totalIncome),
                  PdfColors.green,
                ),
                _buildSummaryItem(
                  'Gastos',
                  _currencyFormat.format(totalExpense),
                  PdfColors.red,
                ),
                _buildSummaryItem(
                  'Balance',
                  _currencyFormat.format(totalIncome - totalExpense),
                  totalIncome >= totalExpense ? PdfColors.green : PdfColors.red,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Tabla de transacciones
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
            },
            headers: ['Fecha', 'Tipo', 'Descripcion', 'Monto'],
            data: transactions.map((tx) {
              return [
                _dateFormat.format(tx.date),
                tx.type.displayName,
                '${tx.categoryName ?? ''}\n${tx.description ?? ''}',
                _currencyFormat.format(tx.amount),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/${fileName ?? 'reporte_${DateTime.now().millisecondsSinceEpoch}'}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfHeader({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange =
          '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Finanzas Familiares',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (dateRange.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            dateRange,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          'Pagina ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Exportar cuentas a CSV
  Future<File> exportAccountsToCSV(List<AccountModel> accounts) async {
    final List<List<dynamic>> rows = [
      ['Nombre', 'Tipo', 'Balance', 'Moneda', 'Banco'],
    ];

    for (final acc in accounts) {
      rows.add([
        acc.name,
        acc.type.displayName,
        acc.balance,
        acc.currency,
        acc.bankName ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/cuentas_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    return file;
  }

  /// Compartir archivo
  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }

  /// Exportar y compartir transacciones
  Future<void> exportAndShareTransactions(
    List<TransactionModel> transactions, {
    required ExportFormat format,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    File file;

    if (format == ExportFormat.csv) {
      file = await exportTransactionsToCSV(transactions);
    } else {
      file = await exportTransactionsToPDF(
        transactions,
        title: title,
        startDate: startDate,
        endDate: endDate,
      );
    }

    await shareFile(
      file,
      subject: title ?? 'Reporte de Finanzas Familiares',
    );
  }
}

enum ExportFormat { csv, pdf }
