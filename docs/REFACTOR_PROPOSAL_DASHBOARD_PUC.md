# Dashboard Refactor Proposal: PUC-Driven Architecture

**Date**: 2026-01-07
**Version**: 2.0.0-Refactor
**Status**: PROPOSED (Pending Approval)

---

## 1. New DashboardRepository (Database-Driven Queries)

**File**: `lib/features/dashboard/data/repositories/dashboard_repository.dart`

```dart
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository(this._db);

  /// Get total balance for a specific AccountClass (PUC classification)
  /// classId: 1 = Activo ("Lo que Tengo"), 2 = Pasivo ("Lo que Debo")
  Future<double> getTotalByClass(String userId, int classId) async {
    final query = _db.select(_db.accounts).join([
      innerJoin(
        _db.accountGroups,
        _db.accountGroups.id.equalsExp(_db.accounts.groupId),
      ),
    ])
      ..where(_db.accounts.userId.equals(userId))
      ..where(_db.accountGroups.classId.equals(classId))
      ..where(_db.accounts.archived.equals(false));

    final results = await query.get();
    return results.fold(0.0, (sum, row) {
      final account = row.readTable(_db.accounts);
      return sum + account.balance;
    });
  }

  /// Get Fixed vs Variable expenses breakdown
  Future<ExpenseBreakdown> getExpenseBreakdown(String userId, DateTime from, DateTime to) async {
    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      innerJoin(
        _db.accountGroups,
        _db.accountGroups.id.equalsExp(_db.accounts.groupId),
      ),
    ])
      ..where(_db.transactions.userId.equals(userId))
      ..where(_db.transactions.type.equals('expense'))
      ..where(_db.transactions.date.isBetweenValues(from, to))
      ..where(_db.accountGroups.classId.equals(5)); // Class 5 = Gastos

    final results = await query.get();

    double fixed = 0.0;
    double variable = 0.0;

    for (final row in results) {
      final transaction = row.readTable(_db.transactions);
      final group = row.readTable(_db.accountGroups);

      if (group.expenseType == 'FIXED') {
        fixed += transaction.amount.abs();
      } else if (group.expenseType == 'VARIABLE') {
        variable += transaction.amount.abs();
      }
    }

    return ExpenseBreakdown(fixed: fixed, variable: variable);
  }

  /// Get all AccountClasses with their totals
  Future<List<PUCClassSummary>> getPUCClassSummaries(String userId) async {
    final classes = await _db.select(_db.accountClasses).get();
    final summaries = <PUCClassSummary>[];

    for (final cls in classes) {
      final total = await getTotalByClass(userId, cls.id);
      summaries.add(PUCClassSummary(
        id: cls.id,
        name: cls.name,
        presentationName: cls.presentationName,
        description: cls.description,
        totalBalance: total,
      ));
    }

    return summaries;
  }
}
```

---

## 2. New Domain Models

### 2.1 PUCClassSummary

**File**: `lib/features/dashboard/domain/models/puc_class_summary.dart`

```dart
class PUCClassSummary {
  final int id;               // 1-5
  final String name;          // "Activo", "Pasivo", etc.
  final String presentationName; // "Lo que Tengo", "Lo que Debo"
  final String description;
  final double totalBalance;

  PUCClassSummary({
    required this.id,
    required this.name,
    required this.presentationName,
    required this.description,
    required this.totalBalance,
  });

  bool get isAsset => id == 1;   // "Lo que Tengo"
  bool get isLiability => id == 2; // "Lo que Debo"
  bool get isExpense => id == 5;  // "Dinero que Pago"
}
```

### 2.2 ExpenseBreakdown

**File**: `lib/features/dashboard/domain/models/expense_breakdown.dart`

```dart
class ExpenseBreakdown {
  final double fixed;      // Gastos Fijos (Obligatorios)
  final double variable;   // Gastos Variables (Estilo de Vida)

  ExpenseBreakdown({required this.fixed, required this.variable});

  double get total => fixed + variable;
  double get fixedPercentage => total > 0 ? (fixed / total) * 100 : 0;
  double get variablePercentage => total > 0 ? (variable / total) * 100 : 0;

  /// Health indicator: Fixed expenses should be < 60% of total expenses
  bool get isHealthy => fixedPercentage <= 60;
}
```

---

## 3. DashboardController (Riverpod Provider)

**File**: `lib/features/dashboard/presentation/providers/dashboard_controller.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/models/puc_class_summary.dart';
import '../../domain/models/expense_breakdown.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(AppDatabase.instance);
});

/// State for Dashboard
class DashboardState {
  final List<PUCClassSummary> pucClasses;
  final ExpenseBreakdown? expenseBreakdown;
  final double monthlyIncome;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.pucClasses = const [],
    this.expenseBreakdown,
    this.monthlyIncome = 0.0,
    this.isLoading = false,
    this.errorMessage,
  });

  // Computed properties
  double get loQueTengo => pucClasses.firstWhere((c) => c.id == 1).totalBalance;
  double get loQueDebo => pucClasses.firstWhere((c) => c.id == 2).totalBalance;
  double get patrimonioNeto => loQueTengo - loQueDebo;

  // Salud Mensual (Income vs Fixed vs Variable)
  bool get hasHealthyFinances {
    if (expenseBreakdown == null || monthlyIncome == 0) return false;
    final totalExpenses = expenseBreakdown!.total;
    return totalExpenses < monthlyIncome * 0.8; // Expenses should be < 80% of income
  }
}

/// Dashboard Controller Provider
final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  return DashboardController(repository, userId);
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final String? _userId;

  DashboardController(this._repository, this._userId) : super(DashboardState()) {
    if (_userId != null) {
      loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    state = DashboardState(isLoading: true);

    try {
      final userId = _userId!;

      // Load PUC class summaries
      final pucClasses = await _repository.getPUCClassSummaries(userId);

      // Load expense breakdown (current month)
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final expenseBreakdown = await _repository.getExpenseBreakdown(userId, from, to);

      // TODO: Get monthly income from transactions
      final monthlyIncome = 0.0; // Placeholder

      state = DashboardState(
        pucClasses: pucClasses,
        expenseBreakdown: expenseBreakdown,
        monthlyIncome: monthlyIncome,
        isLoading: false,
      );
    } catch (e) {
      state = DashboardState(errorMessage: e.toString());
    }
  }
}
```

---

## 4. Refactored DashboardScreen (Data-Driven UI)

**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    if (dashboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finanzas Familiares')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Section 1: "Lo que Tengo" (Class 1 - Activos)
            _buildPUCClassCard(
              context,
              classId: 1,
              presentationName: 'Lo que Tengo',
              amount: dashboardState.loQueTengo,
              color: Colors.green,
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),

            // Section 2: "Lo que Debo" (Class 2 - Pasivos)
            _buildPUCClassCard(
              context,
              classId: 2,
              presentationName: 'Lo que Debo',
              amount: dashboardState.loQueDebo,
              color: Colors.red,
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 16),

            // Section 3: "Salud Mensual" (Income vs Fixed vs Variable)
            _buildMonthlyHealthCard(
              context,
              income: dashboardState.monthlyIncome,
              fixedExpenses: dashboardState.expenseBreakdown?.fixed ?? 0,
              variableExpenses: dashboardState.expenseBreakdown?.variable ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPUCClassCard(
    BuildContext context, {
    required int classId,
    required String presentationName,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(presentationName),
        subtitle: Text('Class $classId'),
        trailing: Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyHealthCard(
    BuildContext context, {
    required double income,
    required double fixedExpenses,
    required double variableExpenses,
  }) {
    final totalExpenses = fixedExpenses + variableExpenses;
    final disponible = income - totalExpenses;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salud Mensual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildHealthRow('Ingresos', income, Colors.green),
            _buildHealthRow('Gastos Fijos', fixedExpenses, Colors.orange),
            _buildHealthRow('Gastos Variables', variableExpenses, Colors.red),
            const Divider(),
            _buildHealthRow('Disponible', disponible, disponible >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Migration Strategy

### Phase 1: Create New Files (No Breaking Changes)
1. Create `dashboard_repository.dart`
2. Create `puc_class_summary.dart`
3. Create `expense_breakdown.dart`
4. Create `dashboard_controller.dart`

### Phase 2: Test New Architecture
1. Write unit tests for DashboardRepository queries
2. Write widget tests for new DashboardScreen
3. Verify PUC JOINs return correct data

### Phase 3: Replace Old Dashboard
1. Rename current `dashboard_screen.dart` to `dashboard_screen_old.dart`
2. Deploy new `dashboard_screen.dart`
3. Monitor for regressions

### Phase 4: Cleanup
1. Delete `dashboard_screen_old.dart`
2. Remove calculation logic from `TransactionProvider`
3. Update CHANGELOG.md with "[2.0.0-Refactor] - Architectural Realignment"

---

## 6. Tests Required (TDD Approach)

### 6.1 Unit Tests

**File**: `test/unit/dashboard_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/dashboard/data/repositories/dashboard_repository.dart';

void main() {
  late DashboardRepository repository;

  setUp(() {
    repository = DashboardRepository(AppDatabase.memory());
  });

  group('getTotalByClass', () {
    test('returns correct total for Class 1 (Activo)', () async {
      // Arrange: Insert test data with groupId = '1105' (Class 1)
      // Act: Call getTotalByClass(userId, 1)
      // Assert: Total matches sum of accounts in Class 1
    });

    test('returns correct total for Class 2 (Pasivo)', () async {
      // Test Class 2 (Lo que Debo)
    });
  });

  group('getExpenseBreakdown', () {
    test('separates fixed vs variable expenses correctly', () async {
      // Arrange: Insert transactions with groupId '5100' (Fixed) and '5300' (Variable)
      // Act: Call getExpenseBreakdown()
      // Assert: fixed and variable totals are correct
    });
  });
}
```

### 6.2 Integration Tests

**File**: `test/integration/dashboard_puc_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard displays PUC classes correctly', (tester) async {
    // Arrange: Mock data with PUC groupIds
    // Act: Pump DashboardScreen
    // Assert: "Lo que Tengo" and "Lo que Debo" are visible with correct totals
  });
}
```

---

## 7. Rollback Plan

If the refactor fails:

```bash
# Revert to previous dashboard
git checkout dashboard_screen_old.dart
mv dashboard_screen_old.dart dashboard_screen.dart

# Remove new files
rm lib/features/dashboard/data/repositories/dashboard_repository.dart
rm lib/features/dashboard/presentation/providers/dashboard_controller.dart

# Revert CHANGELOG
git checkout HEAD~1 -- CHANGELOG.md
```

---

**Approval Required Before Implementation**
**Estimated Effort**: 4-6 hours (with tests)
**Risk Level**: MEDIUM (core UI change, but database is sound)
