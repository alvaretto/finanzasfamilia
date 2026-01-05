import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/accounts/domain/models/account_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../../features/budgets/domain/models/budget_model.dart';
import '../../features/goals/domain/models/goal_model.dart';
import '../../features/recurring/domain/models/recurring_model.dart';

/// Servicio para crear y restaurar respaldos completos de la app
class BackupService {
  BackupService._();
  static final instance = BackupService._();

  /// Crea un respaldo completo de todos los datos
  Future<BackupData> createBackup({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<GoalModel> goals,
    required List<RecurringModel> recurrents,
  }) async {
    return BackupData(
      version: '1.0',
      createdAt: DateTime.now(),
      accounts: accounts,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      recurrents: recurrents,
    );
  }

  /// Exporta el respaldo a archivo JSON y lo comparte
  Future<void> exportAndShareBackup(BackupData backup) async {
    try {
      final jsonData = backup.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'finanzas_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'Respaldo Finanzas Familiares',
        text: 'Respaldo completo creado el ${backup.createdAt.toLocal()}',
      );
    } catch (e) {
      debugPrint('Error al exportar respaldo: $e');
      rethrow;
    }
  }

  /// Importa un respaldo desde un archivo JSON
  Future<BackupData> importBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return BackupData.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error al importar respaldo: $e');
      rethrow;
    }
  }

  /// Valida que el archivo sea un respaldo válido
  Future<bool> validateBackupFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Verificar campos obligatorios
      if (!jsonData.containsKey('version') ||
          !jsonData.containsKey('createdAt') ||
          !jsonData.containsKey('accounts')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Modelo de datos del respaldo
class BackupData {
  final String version;
  final DateTime createdAt;
  final List<AccountModel> accounts;
  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final List<GoalModel> goals;
  final List<RecurringModel> recurrents;

  BackupData({
    required this.version,
    required this.createdAt,
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.recurrents,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'recurrents': recurrents.map((r) => r.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
        version: json['version'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        accounts: (json['accounts'] as List<dynamic>)
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgets: (json['budgets'] as List<dynamic>)
            .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        goals: (json['goals'] as List<dynamic>)
            .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        recurrents: (json['recurrents'] as List<dynamic>)
            .map((e) => RecurringModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Estadísticas del respaldo
  int get totalAccounts => accounts.length;
  int get totalTransactions => transactions.length;
  int get totalBudgets => budgets.length;
  int get totalGoals => goals.length;
  int get totalRecurrents => recurrents.length;
  int get totalItems =>
      totalAccounts + totalTransactions + totalBudgets + totalGoals + totalRecurrents;

  /// Tamaño estimado en KB
  int get estimatedSizeKB {
    final jsonString = jsonEncode(toJson());
    return (jsonString.length / 1024).ceil();
  }
}
