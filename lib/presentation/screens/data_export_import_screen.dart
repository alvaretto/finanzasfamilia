import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/providers/database_provider.dart';
import '../../application/services/export_service.dart';
import '../../application/services/import_service.dart';
import '../../data/local/daos/daos.dart';

/// Provider para ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExportService(
    db: db,
    categoriesDao: CategoriesDao(db),
    transactionsDao: TransactionsDao(db),
  );
});

/// Provider para ImportService
final importServiceProvider = Provider<ImportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ImportService(
    db: db,
    categoriesDao: CategoriesDao(db),
    transactionsDao: TransactionsDao(db),
  );
});

/// Pantalla de Exportación e Importación de Datos
class DataExportImportScreen extends ConsumerStatefulWidget {
  const DataExportImportScreen({super.key});

  @override
  ConsumerState<DataExportImportScreen> createState() =>
      _DataExportImportScreenState();
}

class _DataExportImportScreenState
    extends ConsumerState<DataExportImportScreen> {
  bool _isExporting = false;
  // ignore: prefer_final_fields - Se usará cuando se implemente file_picker
  bool _isImporting = false;
  String? _lastExportPath;
  String? _statusMessage;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar / Importar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            if (_statusMessage != null) ...[
              _StatusCard(
                message: _statusMessage!,
                isError: _isError,
                filePath: _lastExportPath,
              ),
              const SizedBox(height: 16),
            ],

            // Sección Exportar
            _SectionCard(
              title: 'Exportar Datos',
              icon: Icons.upload_file,
              color: colorScheme.primary,
              children: [
                _ExportOption(
                  title: 'Transacciones',
                  subtitle: 'Exportar todos los movimientos',
                  icon: Icons.receipt_long,
                  isLoading: _isExporting,
                  onTapCsv: () => _exportTransactions('csv'),
                  onTapExcel: () => _exportTransactions('excel'),
                ),
                const Divider(height: 1),
                _ExportOption(
                  title: 'Categorías',
                  subtitle: 'Exportar árbol de categorías',
                  icon: Icons.category,
                  isLoading: _isExporting,
                  onTapCsv: () => _exportCategories('csv'),
                  onTapExcel: () => _exportCategories('excel'),
                ),
                const Divider(height: 1),
                _ExportOption(
                  title: 'Datos Completos',
                  subtitle: 'Categorías y cuentas en Excel',
                  icon: Icons.folder_zip,
                  isLoading: _isExporting,
                  onTapExcel: () => _exportReferenceData(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección Importar
            _SectionCard(
              title: 'Importar Datos',
              icon: Icons.download,
              color: colorScheme.tertiary,
              children: [
                _ImportOption(
                  title: 'Importar Transacciones',
                  subtitle: 'Desde archivo CSV o Excel',
                  icon: Icons.receipt_long,
                  isLoading: _isImporting,
                  onTap: _showImportDialog,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Los archivos se guardan en la carpeta de descargas\n'
                      '• Formato CSV compatible con Excel y Google Sheets\n'
                      '• La importación valida los datos antes de insertar\n'
                      '• Las categorías deben existir antes de importar transacciones',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  String _generateFileName(String prefix, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$timestamp.$extension';
  }

  Future<void> _exportTransactions(String format) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _statusMessage = null;
      _lastExportPath = null;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final dir = await _getExportDirectory();
      final fileName = _generateFileName('transacciones', format);
      final filePath = '$dir/$fileName';

      ExportResult result;
      if (format == 'csv') {
        result = await exportService.exportTransactionsToCsv(filePath);
      } else {
        // Para Excel, exportar como parte de datos de referencia
        result = await exportService.exportReferenceDataToExcel(filePath);
      }

      setState(() {
        _isExporting = false;
        if (result.success) {
          _statusMessage =
              'Exportado: ${result.recordCount} registros';
          _lastExportPath = result.filePath;
          _isError = false;
        } else {
          _statusMessage = result.errorMessage ?? 'Error desconocido';
          _isError = true;
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Error: $e';
        _isError = true;
      });
    }
  }

  Future<void> _exportCategories(String format) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _statusMessage = null;
      _lastExportPath = null;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final dir = await _getExportDirectory();
      final fileName = _generateFileName('categorias', format);
      final filePath = '$dir/$fileName';

      ExportResult result;
      if (format == 'csv') {
        result = await exportService.exportCategoriesToCsv(filePath);
      } else {
        result = await exportService.exportCategoriesToExcel(filePath);
      }

      setState(() {
        _isExporting = false;
        if (result.success) {
          _statusMessage =
              'Exportado: ${result.recordCount} categorías';
          _lastExportPath = result.filePath;
          _isError = false;
        } else {
          _statusMessage = result.errorMessage ?? 'Error desconocido';
          _isError = true;
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Error: $e';
        _isError = true;
      });
    }
  }

  Future<void> _exportReferenceData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _statusMessage = null;
      _lastExportPath = null;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final dir = await _getExportDirectory();
      final fileName = _generateFileName('datos_completos', 'xlsx');
      final filePath = '$dir/$fileName';

      final result = await exportService.exportReferenceDataToExcel(filePath);

      setState(() {
        _isExporting = false;
        if (result.success) {
          _statusMessage =
              'Exportado: ${result.recordCount} registros en ${result.sheets.length} hojas';
          _lastExportPath = result.filePath;
          _isError = false;
        } else {
          _statusMessage = result.errorMessage ?? 'Error desconocido';
          _isError = true;
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Error: $e';
        _isError = true;
      });
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Transacciones'),
        content: const Text(
          'La importación desde archivos requiere seleccionar un archivo '
          'CSV o Excel con el formato correcto.\n\n'
          'Columnas requeridas:\n'
          '• id, type, amount, description, categoryId, date\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showImportInstructions();
            },
            child: const Text('Ver instrucciones'),
          ),
        ],
      ),
    );
  }

  void _showImportInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Instrucciones de Importación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Prepara tu archivo CSV o Excel con las siguientes columnas:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildCodeBlock(
                'id,type,amount,description,categoryId,date\n'
                'tx-001,expense,50000,Mercado,cat-alimentacion,2026-01-15\n'
                'tx-002,income,3000000,Salario,cat-salario,2026-01-01',
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Valores válidos para "type":',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text('• expense (gasto)\n• income (ingreso)\n• transfer (transferencia)'),
              const SizedBox(height: 16),
              const Text(
                '3. El categoryId debe coincidir con una categoría existente.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Exporta primero las categorías para ver los IDs disponibles.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Card de sección con título e icono
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: color.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Opción de exportación con botones CSV/Excel
class _ExportOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTapCsv;
  final VoidCallback? onTapExcel;

  const _ExportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    this.onTapCsv,
    this.onTapExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (onTapCsv != null)
              _FormatButton(label: 'CSV', onTap: onTapCsv!),
            if (onTapCsv != null && onTapExcel != null)
              const SizedBox(width: 8),
            if (onTapExcel != null)
              _FormatButton(label: 'Excel', onTap: onTapExcel!),
          ],
        ],
      ),
    );
  }
}

/// Botón de formato (CSV/Excel)
class _FormatButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FormatButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}

/// Opción de importación
class _ImportOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _ImportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: isLoading ? null : onTap,
    );
  }
}

/// Card de estado de operación
class _StatusCard extends StatelessWidget {
  final String message;
  final bool isError;
  final String? filePath;

  const _StatusCard({
    required this.message,
    required this.isError,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (filePath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      filePath!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
