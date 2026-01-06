// test/mocks/mock_providers.dart
//
// Mocks centralizados para tests.
// Incluye providers de cuentas, transacciones, categorías, unidades y establecimientos.
// Ver .claude/skills/testing/TEST_SETUP_GUIDE.md para documentación completa.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/accounts/presentation/providers/account_provider.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:finanzas_familiares/features/transactions/presentation/providers/establishments_provider.dart';
import 'package:finanzas_familiares/features/transactions/presentation/providers/units_provider.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/establishment_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/unit_model.dart';

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

/// Establecimientos mock para tests
final mockEstablishments = <EstablishmentModel>[
  EstablishmentModel(
    id: 'est-1',
    userId: 'test-user',
    name: 'Supermercado Éxito',
    category: 'supermarket',
    address: 'Calle 100 #15-20',
    useCount: 10,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  EstablishmentModel(
    id: 'est-2',
    userId: 'test-user',
    name: 'Restaurante El Corral',
    category: 'restaurant',
    address: 'Carrera 7 #50-30',
    useCount: 5,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

/// Estado mock de establecimientos
const mockEstablishmentsState = EstablishmentsState(
  establishments: [],
  isLoading: false,
);

/// Unidades mock para tests
final mockUnits = <UnitModel>[
  UnitModel(
    id: 'unit-1',
    name: 'Unidad',
    shortName: 'und',
    category: 'unit',
    isSystem: true,
    createdAt: DateTime.now(),
  ),
  UnitModel(
    id: 'unit-2',
    name: 'Kilogramo',
    shortName: 'kg',
    category: 'weight',
    isSystem: true,
    createdAt: DateTime.now(),
  ),
];

/// Estado mock de unidades
const mockUnitsState = UnitsState(
  units: [],
  isLoading: false,
);

/// Unidades mock con datos reales
final mockUnitsWithData = <UnitModel>[
  const UnitModel(
    id: 'unit-1',
    name: 'Unidad',
    shortName: 'und',
    category: 'unit',
    isSystem: true,
  ),
  const UnitModel(
    id: 'unit-2',
    name: 'Kilogramo',
    shortName: 'kg',
    category: 'weight',
    isSystem: true,
  ),
  const UnitModel(
    id: 'unit-3',
    name: 'Gramo',
    shortName: 'g',
    category: 'weight',
    isSystem: true,
  ),
  const UnitModel(
    id: 'unit-4',
    name: 'Litro',
    shortName: 'L',
    category: 'volume',
    isSystem: true,
  ),
];

/// Unidades agrupadas por categoría
final mockUnitsGrouped = <String, List<UnitModel>>{
  'unit': [mockUnitsWithData[0]],
  'weight': [mockUnitsWithData[1], mockUnitsWithData[2]],
  'volume': [mockUnitsWithData[3]],
};

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

/// Mock Notifier para establecimientos (no hace nada async)
class MockEstablishments extends Establishments {
  @override
  EstablishmentsState build() {
    return mockEstablishmentsState;
  }
}

/// Mock Notifier para unidades (no hace nada async)
class MockUnits extends Units {
  @override
  UnitsState build() {
    return mockUnitsState;
  }
}

/// Estado mock de transacciones con categorías precargadas para tests
/// Usar con transactionsProvider.overrideWithValue(mockTransactionsStateWithCategories)
final mockTransactionsStateWithCategories = TransactionsState(
  transactions: [],
  categories: mockAllCategories,
  isLoading: false,
  isSyncing: false,
);

/// Lista de overrides para tests E2E
/// Incluye todos los providers necesarios para evitar acceso a DB/Supabase
///
/// NOTA: No se hace override de transactionsProvider directamente porque
/// es un StateNotifierProvider que requiere repositorios. En su lugar,
/// se hace override de los providers derivados (categorías).
List<Override> get testProviderOverrides => [
      // Override de cuentas activas (Provider<List<AccountModel>>)
      activeAccountsProvider.overrideWith((ref) => mockAccounts),

      // Override de categorias (Provider<List<CategoryModel>>)
      // Estos providers derivan de transactionsProvider pero los sobreescribimos
      categoriesProvider.overrideWith((ref) => mockAllCategories),
      expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
      incomeCategoriesProvider.overrideWith((ref) => mockIncomeCategories),

      // Override de establecimientos (evita acceso a DB)
      establishmentsProvider.overrideWith(() => MockEstablishments()),

      // Override de unidades (evita acceso a DB)
      unitsProvider.overrideWith(() => MockUnits()),

      // Override de unidades agrupadas
      unitsGroupedProvider.overrideWith((ref) => mockUnitsGrouped),
      unitsListProvider.overrideWith((ref) => mockUnitsWithData),
    ];

/// Lista de overrides para tests de estado vacío
/// Usa listas vacías para simular un usuario sin datos
List<Override> get emptyStateProviderOverrides => [
      // Override de cuentas activas vacío
      activeAccountsProvider.overrideWith((ref) => <AccountModel>[]),

      // Override de categorias (mantener para que funcione UI)
      categoriesProvider.overrideWith((ref) => mockAllCategories),
      expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
      incomeCategoriesProvider.overrideWith((ref) => mockIncomeCategories),

      // Override de establecimientos (evita acceso a DB)
      establishmentsProvider.overrideWith(() => MockEstablishments()),

      // Override de unidades (evita acceso a DB)
      unitsProvider.overrideWith(() => MockUnits()),

      // Override de unidades agrupadas vacías
      unitsGroupedProvider.overrideWith((ref) => <String, List<UnitModel>>{}),
      unitsListProvider.overrideWith((ref) => <UnitModel>[]),
    ];
