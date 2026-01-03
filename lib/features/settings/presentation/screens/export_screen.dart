import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _format = ExportFormat.pdf;
  ExportDataType _dataType = ExportDataType.transactions;
  DateTimeRange? _dateRange;
  bool _isExporting = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Tipo de datos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos a exportar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...ExportDataType.values.map(
                    (type) => RadioListTile<ExportDataType>(
                      value: type,
                      groupValue: _dataType,
                      onChanged: (value) => setState(() => _dataType = value!),
                      title: Text(type.displayName),
                      subtitle: Text(type.description),
                      secondary: Icon(type.icon, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Formato
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formato',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOption(
                          icon: Icons.picture_as_pdf,
                          label: 'PDF',
                          description: 'Reporte visual',
                          isSelected: _format == ExportFormat.pdf,
                          onTap: () => setState(() => _format = ExportFormat.pdf),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _FormatOption(
                          icon: Icons.table_chart,
                          label: 'CSV',
                          description: 'Datos en tabla',
                          isSelected: _format == ExportFormat.csv,
                          onTap: () => setState(() => _format = ExportFormat.csv),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Rango de fechas (solo para transacciones)
          if (_dataType == ExportDataType.transactions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periodo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        _dateRange != null
                            ? '${_dateFormat.format(_dateRange!.start)} - ${_dateFormat.format(_dateRange!.end)}'
                            : 'Todo el historial',
                      ),
                      subtitle: Text(
                        _dateRange != null
                            ? '${_dateRange!.duration.inDays + 1} dias'
                            : 'Sin filtro de fecha',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dateRange != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dateRange = null),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: _selectDateRange,
                    ),
                    const Divider(),
                    // Atajos de periodo
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _PeriodChip(
                          label: 'Este mes',
                          onTap: () => _setCurrentMonth(),
                        ),
                        _PeriodChip(
                          label: 'Mes pasado',
                          onTap: () => _setLastMonth(),
                        ),
                        _PeriodChip(
                          label: 'Este anio',
                          onTap: () => _setCurrentYear(),
                        ),
                        _PeriodChip(
                          label: 'Ultimos 90 dias',
                          onTap: () => _setLast90Days(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Boton exportar
          FilledButton.icon(
            onPressed: _isExporting ? null : _export,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exportando...' : 'Exportar y Compartir'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
    );

    if (result != null) {
      setState(() => _dateRange = result);
    }
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    setState(() {
      _dateRange = DateTimeRange(
        start: lastMonth,
        end: lastDayOfLastMonth,
      );
    });
  }

  void _setCurrentYear() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: now,
      );
    });
  }

  void _setLast90Days() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 90)),
        end: now,
      );
    });
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      switch (_dataType) {
        case ExportDataType.transactions:
          await _exportTransactions();
          break;
        case ExportDataType.accounts:
          await _exportAccounts();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportacion completada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTransactions() async {
    var transactions = ref.read(transactionsProvider).transactions;

    // Filtrar por fecha si hay rango
    if (_dateRange != null) {
      transactions = transactions.where((tx) {
        return tx.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay transacciones para exportar'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    await ExportService.instance.exportAndShareTransactions(
      transactions,
      format: _format,
      title: 'Reporte de Transacciones',
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  Future<void> _exportAccounts() async {
    final accounts = ref.read(activeAccountsProvider);

    if (accounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay cuentas para exportar'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final file = await ExportService.instance.exportAccountsToCSV(accounts);
    await ExportService.instance.shareFile(
      file,
      subject: 'Cuentas - Finanzas Familiares',
    );
  }
}

enum ExportDataType {
  transactions,
  accounts;

  String get displayName {
    switch (this) {
      case transactions:
        return 'Transacciones';
      case accounts:
        return 'Cuentas';
    }
  }

  String get description {
    switch (this) {
      case transactions:
        return 'Ingresos, gastos y transferencias';
      case accounts:
        return 'Listado de cuentas y balances';
    }
  }

  IconData get icon {
    switch (this) {
      case transactions:
        return Icons.receipt_long;
      case accounts:
        return Icons.account_balance_wallet;
    }
  }
}

class _FormatOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
