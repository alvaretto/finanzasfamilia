// test/mocks/mock_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/accounts/presentation/providers/account_provider.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/providers/transaction_provider.dart';

/// Cuentas mock para tests
final mockAccounts = [
  AccountModel(
    id: 'acc-1',
    userId: 'test-user',
    name: 'Cuenta Bancaria',
    type: AccountType.bank,
    currency: 'COP',
    balance: 5000000.0,
    isActive: true,
  ),
  AccountModel(
    id: 'acc-2',
    userId: 'test-user',
    name: 'Efectivo',
    type: AccountType.cash,
    currency: 'COP',
    balance: 500000.0,
    isActive: true,
  ),
  AccountModel(
    id: 'acc-3',
    userId: 'test-user',
    name: 'Nequi',
    type: AccountType.wallet,
    currency: 'COP',
    balance: 150000.0,
    isActive: true,
  ),
];

/// Categorias mock de gasto
final mockExpenseCategories = [
  const CategoryModel(
    id: 'cat-1',
    name: 'Alimentacion',
    type: 'expense',
    icon: 'restaurant',
    color: '#4CAF50',
  ),
  const CategoryModel(
    id: 'cat-2',
    name: 'Transporte',
    type: 'expense',
    icon: 'directions_car',
    color: '#2196F3',
  ),
  const CategoryModel(
    id: 'cat-3',
    name: 'Vivienda',
    type: 'expense',
    icon: 'home',
    color: '#FF9800',
  ),
  const CategoryModel(
    id: 'cat-4',
    name: 'Entretenimiento',
    type: 'expense',
    icon: 'movie',
    color: '#9C27B0',
  ),
];

/// Categorias mock de ingreso
final mockIncomeCategories = [
  const CategoryModel(
    id: 'cat-10',
    name: 'Salario',
    type: 'income',
    icon: 'work',
    color: '#4CAF50',
  ),
  const CategoryModel(
    id: 'cat-11',
    name: 'Ventas',
    type: 'income',
    icon: 'trending_up',
    color: '#2196F3',
  ),
  const CategoryModel(
    id: 'cat-12',
    name: 'Inversiones',
    type: 'income',
    icon: 'savings',
    color: '#FF9800',
  ),
];

/// Todas las categorias
final mockAllCategories = [...mockExpenseCategories, ...mockIncomeCategories];

/// Estado mock de cuentas
final mockAccountsState = AccountsState(
  accounts: mockAccounts,
  isLoading: false,
  isSyncing: false,
  totalBalance: mockAccounts.fold(0.0, (sum, a) => sum + a.balance),
);

/// Estado mock de transacciones
final mockTransactionsState = TransactionsState(
  transactions: [],
  categories: mockAllCategories,
  isLoading: false,
  isSyncing: false,
);

/// Lista de overrides para tests E2E
/// Solo override de providers simples (no StateNotifier)
List<Override> get testProviderOverrides => [
      // Override de cuentas activas (Provider<List<AccountModel>>)
      activeAccountsProvider.overrideWith((ref) => mockAccounts),

      // Override de categorias (Provider<List<CategoryModel>>)
      expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
      incomeCategoriesProvider.overrideWith((ref) => mockIncomeCategories),
    ];

/// Lista de overrides para tests de estado vacío
/// Usa listas vacías para simular un usuario sin datos
List<Override> get emptyStateProviderOverrides => [
      // Override de cuentas activas vacío
      activeAccountsProvider.overrideWith((ref) => <AccountModel>[]),

      // Override de categorias (mantener para que funcione UI)
      expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
      incomeCategoriesProvider.overrideWith((ref) => mockIncomeCategories),
    ];
