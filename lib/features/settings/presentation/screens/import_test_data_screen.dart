import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Pantalla para importar datos de prueba
class ImportTestDataScreen extends ConsumerStatefulWidget {
  const ImportTestDataScreen({super.key});

  @override
  ConsumerState<ImportTestDataScreen> createState() => _ImportTestDataScreenState();
}

class _ImportTestDataScreenState extends ConsumerState<ImportTestDataScreen> {
  int _transactionCount = 50;
  int _daysBack = 30;
  bool _createTestAccount = true;
  bool _isGenerating = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de Prueba'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Warning card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Los datos generados se mezclaran con tus datos reales. '
                      'Usa una cuenta de prueba si no quieres afectar tus finanzas.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Transaction count slider
          Text(
            'Cantidad de transacciones: $_transactionCount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _transactionCount.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            label: '$_transactionCount',
            onChanged: _isGenerating
                ? null
                : (value) {
                    setState(() => _transactionCount = value.round());
                  },
          ),

          const SizedBox(height: AppSpacing.md),

          // Days back slider
          Text(
            'Dias hacia atras: $_daysBack',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _daysBack.toDouble(),
            min: 7,
            max: 90,
            divisions: 11,
            label: '$_daysBack dias',
            onChanged: _isGenerating
                ? null
                : (value) {
                    setState(() => _daysBack = value.round());
                  },
          ),

          const SizedBox(height: AppSpacing.md),

          // Create test account option
          SwitchListTile(
            title: const Text('Crear cuenta de prueba'),
            subtitle: const Text('Crea una cuenta "Pruebas" para los datos'),
            value: _createTestAccount,
            onChanged: _isGenerating
                ? null
                : (value) {
                    setState(() => _createTestAccount = value);
                  },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Status
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status.contains('Error')
                      ? AppColors.error
                      : _status.contains('completado')
                          ? Colors.green
                          : AppColors.primary,
                ),
              ),
            ),

          // Generate button
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateTestData,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(_isGenerating ? 'Generando...' : 'Generar Datos'),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info section
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Datos que se generaran:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildInfoTile(Icons.store, 'Supermercados', 'Exito, Carulla, D1, Ara'),
          _buildInfoTile(Icons.restaurant, 'Restaurantes', 'Rappi, Crepes, El Corral'),
          _buildInfoTile(Icons.directions_car, 'Transporte', 'Uber, DiDi, TransMilenio'),
          _buildInfoTile(Icons.subscriptions, 'Suscripciones', 'Netflix, Spotify, HBO'),
          _buildInfoTile(Icons.payments, 'Ingresos', 'Salario, bonificaciones'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }

  Future<void> _generateTestData() async {
    setState(() {
      _isGenerating = true;
      _status = 'Iniciando generacion...';
    });

    try {
      String accountId;

      if (_createTestAccount) {
        setState(() => _status = 'Creando cuenta de prueba...');
        accountId = await _createTestAccountIfNeeded();

        // ✅ FIX: Sincronizar cuenta ANTES de crear transacciones
        setState(() => _status = 'Sincronizando cuenta a Supabase...');
        await ref.read(accountsProvider.notifier).syncAccounts();
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // Use first available account
        final accountsState = ref.read(accountsProvider);
        final accounts = accountsState.accounts;
        if (accounts.isEmpty) {
          setState(() => _status = 'Creando cuenta de prueba (no hay cuentas)...');
          accountId = await _createTestAccountIfNeeded();

          // ✅ FIX: Sincronizar cuenta ANTES de crear transacciones
          setState(() => _status = 'Sincronizando cuenta a Supabase...');
          await ref.read(accountsProvider.notifier).syncAccounts();
          await Future.delayed(const Duration(seconds: 2));
        } else {
          accountId = accounts.first.id;
        }
      }

      setState(() => _status = 'Generando $_transactionCount transacciones...');

      final transactionData = _generateTransactionData();

      setState(() => _status = 'Guardando transacciones...');

      int saved = 0;
      for (final tx in transactionData) {
        await ref.read(transactionsProvider.notifier).createTransaction(
          accountId: accountId,
          amount: tx.amount,
          type: tx.type,
          description: tx.description,
          date: tx.date,
        );
        saved++;

        // ✅ FIX: Sincronizar en batches cada 10 transacciones
        if (saved % 10 == 0) {
          setState(() => _status = 'Guardando... $saved/$_transactionCount (sincronizando...)');
          await ref.read(transactionsProvider.notifier).syncTransactions();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // ✅ FIX: Sincronización final de transacciones restantes
      setState(() => _status = 'Sincronizando transacciones finales...');
      await ref.read(transactionsProvider.notifier).syncTransactions();
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isGenerating = false;
        _status = 'Generacion completada: $_transactionCount transacciones';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se generaron $_transactionCount transacciones'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<String> _createTestAccountIfNeeded() async {
    final accountsState = ref.read(accountsProvider);
    final accounts = accountsState.accounts;

    // Check if test account already exists
    final existing = accounts.where((a) => a.name == 'Cuenta Pruebas').firstOrNull;
    if (existing != null) {
      return existing.id;
    }

    // Create test account using the provider
    final success = await ref.read(accountsProvider.notifier).createAccount(
      name: 'Cuenta Pruebas',
      type: AccountType.bank,
      currency: 'COP',
      balance: 5000000, // 5M COP inicial
      color: '#9333ea', // Purple
      icon: 'science',
      bankName: 'Banco de Pruebas',
    );

    if (!success) {
      throw Exception('No se pudo crear la cuenta de prueba');
    }

    // Wait a bit for the account to be created and refresh
    await Future.delayed(const Duration(milliseconds: 500));

    // Get the newly created account
    final updatedState = ref.read(accountsProvider);
    final newAccount = updatedState.accounts
        .where((a) => a.name == 'Cuenta Pruebas')
        .firstOrNull;

    if (newAccount == null) {
      throw Exception('No se encontro la cuenta de prueba creada');
    }

    return newAccount.id;
  }

  List<_TransactionData> _generateTransactionData() {
    final random = Random();
    final transactions = <_TransactionData>[];

    // Merchants with realistic Colombian prices
    final expenses = [
      // Supermercados
      ('Exito', -50000, -350000),
      ('Carulla', -80000, -500000),
      ('D1', -20000, -150000),
      ('Ara', -25000, -180000),
      ('Olimpica', -40000, -280000),
      // Restaurantes
      ('Rappi - Restaurante', -15000, -80000),
      ('Crepes & Waffles', -35000, -120000),
      ('El Corral', -20000, -60000),
      ('Frisby', -18000, -50000),
      // Transporte
      ('Uber', -8000, -45000),
      ('DiDi', -7000, -40000),
      ('Gasolina Terpel', -50000, -200000),
      ('TransMilenio', -2950, -2950),
      // Suscripciones
      ('Netflix', -26900, -44900),
      ('Spotify', -16900, -26900),
      ('HBO Max', -24900, -34900),
      // Servicios
      ('EPM Servicios', -80000, -350000),
      ('Claro Internet', -60000, -150000),
      // Salud
      ('Farmatodo', -15000, -120000),
      ('Drogas La Rebaja', -10000, -80000),
    ];

    final incomes = [
      ('Salario mensual', 2500000, 8000000),
      ('Bonificacion', 500000, 2000000),
      ('Freelance', 200000, 3000000),
      ('Transferencia recibida', 50000, 1000000),
    ];

    for (int i = 0; i < _transactionCount; i++) {
      final isIncome = random.nextDouble() < 0.15; // 15% income
      final daysAgo = random.nextInt(_daysBack);
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      if (isIncome) {
        final income = incomes[random.nextInt(incomes.length)];
        final amount = income.$2 + random.nextInt(income.$3 - income.$2);
        transactions.add(_TransactionData(
          description: income.$1,
          amount: amount.toDouble(),
          type: TransactionType.income,
          date: date,
        ));
      } else {
        final expense = expenses[random.nextInt(expenses.length)];
        final minAmount = expense.$2.abs();
        final maxAmount = expense.$3.abs();
        final amount = minAmount + random.nextInt(maxAmount - minAmount + 1);
        transactions.add(_TransactionData(
          description: expense.$1,
          amount: -amount.toDouble(), // Negative for expense
          type: TransactionType.expense,
          date: date,
        ));
      }
    }

    // Sort by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}

/// Helper class for transaction data
class _TransactionData {
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;

  _TransactionData({
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });
}
