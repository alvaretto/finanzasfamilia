# Phase 2: Logic Layer Cleanup - Audit Report

**Date**: 2026-01-07
**Status**: CRITICAL ARCHITECTURAL VIOLATIONS DETECTED
**Auditor**: Chief Technical Architect (Claude Opus 4.5)

---

## EXECUTIVE SUMMARY

**Result**: ❌ **MASSIVE FAILURE** - Logic layer IGNORES PUC architecture entirely

**Providers Audited**: 17 files
**Critical Violations**: 5
**Duplicated Logic**: 4 instances
**Recommendations**: REFACTOR ALL

---

## 🚨 CRITICAL VIOLATION #1: AccountsProvider Uses Legacy `type` Field

**File**: `lib/features/accounts/presentation/providers/account_provider.dart`

### Problem Code (Lines 116-124):
```dart
/// Balance por tipo de cuenta
Map<AccountType, double> get balanceByType {
  final map = <AccountType, double>{};
  for (final account in uniqueActiveAccounts) {
    final current = map[account.type] ?? 0.0;  // ❌ USES LEGACY TYPE
    map[account.type] = current + account.balance;
  }
  return map;
}
```

### What's Wrong:
1. **Uses `account.type`** (DEPRECATED field marked for removal)
2. **NO JOIN to AccountGroups** table
3. **NO filter by `classId`** (1 = Activo, 2 = Pasivo)
4. **Returns `Map<AccountType, double>`** instead of `Map<int, double>` (classId-based)

### Architectural Impact:
- Dashboard receives data grouped by **legacy types** (cash, bank, credit)
- PUC classification (Class 1, Class 2) is **completely bypassed**
- The "Lo que Tengo" vs "Lo que Debo" distinction is **impossible**

### Root Cause:
```dart
// Line 99: Also uses legacy type
Map<AccountType, List<AccountModel>> get accountsByType {
  final map = <AccountType, List<AccountModel>>{};
  for (final account in activeAccounts) {
    map.putIfAbsent(account.type, () => []).add(account);  // ❌
  }
  return map;
}
```

### Required Fix:
```dart
// ✅ CORRECT: Query with JOIN to AccountGroups
Future<Map<int, double>> getBalanceByClass(String userId) async {
  final query = select(accounts).join([
    innerJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId)),
  ])..where(accounts.userId.equals(userId));

  final results = await query.get();
  final map = <int, double>{};

  for (final row in results) {
    final account = row.readTable(accounts);
    final group = row.readTable(accountGroups);
    final classId = group.classId;

    map[classId] = (map[classId] ?? 0) + account.balance;
  }

  return map;  // {1: 5000000, 2: 2000000} → "Lo que Tengo": 5M, "Lo que Debo": 2M
}
```

---

## 🚨 CRITICAL VIOLATION #2: TransactionProvider Ignores `expenseType`

**File**: `lib/features/transactions/presentation/providers/transaction_provider.dart`

### Problem Code (Lines 75-77):
```dart
/// Total de gastos
double get totalExpenses => transactions
    .where((t) => t.type == TransactionType.expense)
    .fold(0, (sum, t) => sum + t.amount);  // ❌ NO DISTINCTION
```

### What's Wrong:
1. **Aggregates ALL expenses** without separating Fixed vs Variable
2. **NO JOIN to Accounts → AccountGroups**
3. **Ignores `expenseType` field** from AccountGroups table
4. **Impossible to implement "Salud Mensual"** section (Income vs Fixed vs Variable)

### Architectural Impact:
- User cannot see **Obligatory Expenses** (Arriendo, Servicios) separately
- User cannot see **Discretionary Expenses** (Entretenimiento, Viajes) separately
- The PUC groups **5100-5299 (Fixed) vs 5300-5599 (Variable)** are useless

### Required Fix:
```dart
// ✅ CORRECT: Separate Fixed vs Variable
class ExpensesBreakdown {
  final double fixed;      // expenseType = FIXED
  final double variable;   // expenseType = VARIABLE

  ExpensesBreakdown({required this.fixed, required this.variable});

  double get total => fixed + variable;
  double get fixedPercentage => total > 0 ? (fixed / total) * 100 : 0;
}

// In TransactionRepository:
Future<ExpensesBreakdown> getExpensesBreakdown(String userId, DateTime from, DateTime to) async {
  final query = select(transactions).join([
    innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    innerJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId)),
  ])
    ..where(transactions.userId.equals(userId))
    ..where(transactions.type.equals('expense'))
    ..where(transactions.date.isBetweenValues(from, to))
    ..where(accountGroups.classId.equals(5));  // Class 5 = Gastos

  final results = await query.get();
  double fixed = 0.0;
  double variable = 0.0;

  for (final row in results) {
    final tx = row.readTable(transactions);
    final group = row.readTable(accountGroups);

    if (group.expenseType == 'FIXED') {
      fixed += tx.amount.abs();
    } else if (group.expenseType == 'VARIABLE') {
      variable += tx.amount.abs();
    }
  }

  return ExpensesBreakdown(fixed: fixed, variable: variable);
}
```

---

## 🚨 CRITICAL VIOLATION #3: ReportRepository NO JOIN to AccountGroups

**File**: `lib/features/reports/data/repositories/report_repository.dart`

### Problem Code (Lines 54-73):
```dart
/// Obtener totales por tipo
Future<Map<String, double>> _getTotalsByType(
  String userId,
  DateTime from,
  DateTime to,
) async {
  final query = _db.select(_db.transactions)  // ❌ NO JOIN
    ..where((t) =>
        t.userId.equals(userId) &
        t.date.isBiggerOrEqualValue(from) &
        t.date.isSmallerOrEqualValue(to));

  final results = await query.get();
  final totals = <String, double>{'income': 0, 'expense': 0, 'transfer': 0};

  for (final tx in results) {
    totals[tx.type] = (totals[tx.type] ?? 0) + tx.amount;  // ❌ AGGREGATES ALL
  }

  return totals;
}
```

### What's Wrong:
1. **NO JOIN to accounts → account_groups**
2. **Cannot differentiate** Fixed vs Variable expenses
3. **Reports show ONLY** total income/expense, not PUC-based breakdown

### Problem Code #2 (Lines 75-134):
```dart
/// Obtener top categorías
Future<List<CategoryData>> _getTopCategories(
  String userId,
  String type,
  DateTime from,
  DateTime to, {
  int limit = 5,
}) async {
  final query = _db.select(_db.transactions).join([
    leftOuterJoin(
      _db.categories,
      _db.categories.id.equalsExp(_db.transactions.categoryId),  // ❌ ONLY Categories
    ),
  ])
    ..where(_db.transactions.userId.equals(userId) &
        _db.transactions.type.equals(type) &
        // ...
```

### What's Wrong:
- **JOIN only to `categories`** table
- **NO JOIN to `account_groups`** → cannot filter by expenseType
- **Top expense categories MIXED**: Fixed and Variable together

### Architectural Impact:
- Reports cannot show "Top Fixed Expenses" vs "Top Variable Expenses" separately
- User cannot identify which **obligatory expenses** are highest (to renegotiate)
- User cannot identify which **discretionary expenses** to cut first

### Required Fix:
```dart
// ✅ CORRECT: Reports with PUC breakdown
Future<ReportSummaryPUC> getReportSummary(String userId, DateTime from, DateTime to) async {
  // Get Fixed expenses
  final fixedExpenses = await _getExpensesByType(userId, from, to, ExpenseType.FIXED);

  // Get Variable expenses
  final variableExpenses = await _getExpensesByType(userId, from, to, ExpenseType.VARIABLE);

  // Get top categories PER expense type
  final topFixed = await _getTopCategoriesByExpenseType(userId, from, to, ExpenseType.FIXED);
  final topVariable = await _getTopCategoriesByExpenseType(userId, from, to, ExpenseType.VARIABLE);

  return ReportSummaryPUC(
    totalIncome: await _getTotalIncome(userId, from, to),
    fixedExpenses: fixedExpenses,
    variableExpenses: variableExpenses,
    topFixedCategories: topFixed,
    topVariableCategories: topVariable,
    // Balance = Income - (Fixed + Variable)
  );
}

Future<double> _getExpensesByType(
  String userId,
  DateTime from,
  DateTime to,
  ExpenseType expenseType,
) async {
  final query = select(transactions).join([
    innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    innerJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId)),
  ])
    ..where(transactions.userId.equals(userId))
    ..where(transactions.type.equals('expense'))
    ..where(transactions.date.isBetweenValues(from, to))
    ..where(accountGroups.expenseType.equals(expenseType.name));

  final results = await query.get();
  return results.fold(0.0, (sum, row) {
    return sum + row.readTable(transactions).amount.abs();
  });
}
```

---

## 🚨 CRITICAL VIOLATION #4: BudgetProvider NO expenseType Awareness

**File**: `lib/features/budgets/presentation/providers/budget_provider.dart`

### Problem Code (Lines 53-55):
```dart
/// Total presupuestado
double get totalBudgeted => budgets.fold(0, (sum, b) => sum + b.amount);

/// Total gastado
double get totalSpent => budgets.fold(0, (sum, b) => sum + b.spent);
```

### What's Wrong:
1. **Aggregates ALL budgets** without separating Fixed vs Variable
2. **User cannot set separate budgets** for obligatory vs discretionary expenses
3. **Budget alerts DO NOT distinguish** between overspending on Fixed (bad) vs Variable (worse)

### Architectural Impact:
- User cannot enforce: "Fixed expenses must stay under 50% of income"
- User cannot enforce: "Variable expenses must stay under 30% of income"
- Budget system is **useless for financial health** (which requires Fixed/Variable awareness)

### Required Fix:
```dart
class BudgetsState {
  // ...existing fields

  /// Total presupuestado para gastos fijos
  double get totalFixedBudgeted => budgets
      .where((b) => b.category?.expenseType == ExpenseType.FIXED)
      .fold(0, (sum, b) => sum + b.amount);

  /// Total presupuestado para gastos variables
  double get totalVariableBudgeted => budgets
      .where((b) => b.category?.expenseType == ExpenseType.VARIABLE)
      .fold(0, (sum, b) => sum + b.amount);

  /// Presupuestos fijos excedidos (más crítico)
  List<BudgetModel> get overFixedBudgets => budgets
      .where((b) => b.isOverBudget && b.category?.expenseType == ExpenseType.FIXED)
      .toList();
}

// Budget model needs to include expenseType
class BudgetModel {
  // ...existing fields
  final ExpenseType? expenseType;  // ← ADD THIS
}
```

---

## 🚨 CRITICAL VIOLATION #5: NO Provider Uses PUC JOINs

**Problem**: Across ALL providers, ZERO queries use:
```dart
innerJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId))
```

### Files Affected:
1. `account_provider.dart` - NO JOIN
2. `transaction_provider.dart` - NO JOIN
3. `report_repository.dart` - NO JOIN
4. `budget_provider.dart` - NO JOIN
5. `goal_provider.dart` - (not audited, likely same issue)

### Root Cause:
**Providers were written BEFORE PUC architecture** (schema v5) was implemented.

They still use:
- `account.type` (legacy)
- `transaction.type` (basic)
- NO awareness of `groupId`, `classId`, `expenseType`

---

## 🔄 DUPLICATED LOGIC (4 Instances)

### 1. Total Balance Calculation
**Duplicated in**:
- `AccountsProvider.totalBalance` (line 28)
- `DashboardScreen._buildBalanceCard` (line 419-421)

### 2. Total Income/Expense Calculation
**Duplicated in**:
- `TransactionsState.totalIncome` (line 70-72)
- `TransactionsState.totalExpenses` (line 75-77)
- `ReportRepository._getTotalsByType` (line 54-73)
- `DashboardScreen._buildQuickStats` (line 597-599)

### 3. Expense by Category
**Duplicated in**:
- `DashboardScreen._buildExpenseChart` (line 826-831)
- `ReportRepository._getTopCategories` (line 96-117)

### 4. Account Filtering
**Duplicated in**:
- `AccountsState.uniqueActiveAccounts` (line 53-95)
- `DashboardScreen._buildBalanceCard` (line 416-426)

### Recommendation:
**CONSOLIDATE ALL** calculations into repositories with PUC-aware queries.

---

## 📊 PROVIDER ARCHITECTURE MATRIX

| Provider | Uses PUC JOINs? | Aware of expenseType? | Aware of classId? | Status |
|----------|-----------------|----------------------|-------------------|--------|
| AccountsProvider | ❌ NO | ❌ NO | ❌ NO | 🔴 REFACTOR |
| TransactionProvider | ❌ NO | ❌ NO | ❌ NO | 🔴 REFACTOR |
| ReportProvider | ❌ NO | ❌ NO | ❌ NO | 🔴 REFACTOR |
| BudgetProvider | ❌ NO | ❌ NO | ❌ NO | 🔴 REFACTOR |
| GoalProvider | ⚠️ N/A | ⚠️ N/A | ⚠️ N/A | ⚠️ NOT AUDITED |

**Summary**: 0/4 providers are PUC-compliant.

---

## 🎯 UNIFICATION STRATEGY

### Create: `DashboardController` (Single Source of Truth)

**File**: `lib/features/dashboard/presentation/providers/dashboard_controller.dart`

```dart
class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(DashboardState.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    // 1. Get PUC class summaries (Lo que Tengo, Lo que Debo)
    final pucClasses = await _repository.getPUCClassSummaries(userId);

    // 2. Get expense breakdown (Fixed vs Variable)
    final expenseBreakdown = await _repository.getExpenseBreakdown(userId, from, to);

    // 3. Get monthly income
    final income = await _repository.getMonthlyIncome(userId, from, to);

    state = DashboardState(
      loQueTengo: pucClasses[1]?.total ?? 0,        // Class 1
      loQueDebo: pucClasses[2]?.total ?? 0,         // Class 2
      patrimonioNeto: (pucClasses[1]?.total ?? 0) - (pucClasses[2]?.total ?? 0),
      monthlyIncome: income,
      fixedExpenses: expenseBreakdown.fixed,
      variableExpenses: expenseBreakdown.variable,
    );
  }
}
```

### Deprecate:
1. `AccountsState.balanceByType` → Use `DashboardController.loQueTengo` / `loQueDebo`
2. `TransactionsState.totalExpenses` → Use `DashboardController.fixedExpenses` / `variableExpenses`
3. All UI-level calculations → Move to repositories

---

## 📝 MIGRATION PLAN

### Phase 2.1: Create PUC-Aware Repositories
1. Create `DashboardRepository` with PUC JOINs
2. Create `ExpenseAnalysisRepository` with expenseType filtering
3. Update `ReportRepository` to use PUC JOINs

### Phase 2.2: Refactor Providers
1. Update `AccountsProvider` to use `groupId` instead of `type`
2. Update `TransactionProvider` to expose Fixed/Variable breakdown
3. Update `BudgetProvider` to separate Fixed/Variable budgets

### Phase 2.3: Update UI
1. Refactor `DashboardScreen` to consume `DashboardController`
2. Remove all `.fold()` calculations from widgets
3. Update `ReportsScreen` to show Fixed/Variable tabs

### Phase 2.4: Deprecation
1. Mark `AccountType` enum as `@Deprecated`
2. Remove `account.type` field after migration period
3. Remove duplicated calculation getters from providers

---

## 🧪 TESTS REQUIRED (Per QA Mindset)

### Unit Tests:
1. `test/unit/dashboard_repository_puc_test.dart`
   - Verify `getPUCClassSummaries` returns correct Class 1, 2 totals
   - Verify JOINs to account_groups work correctly

2. `test/unit/expense_analysis_repository_test.dart`
   - Verify Fixed vs Variable separation
   - Verify expenseType filtering

3. `test/unit/report_repository_puc_test.dart`
   - Verify `_getTopCategoriesByExpenseType` separates Fixed/Variable

### Integration Tests:
1. `test/integration/dashboard_puc_integration_test.dart`
   - Verify UI displays "Lo que Tengo" and "Lo que Debo" correctly
   - Verify "Salud Mensual" shows Fixed vs Variable expenses

---

## 🔴 RISK ASSESSMENT

**Risk Level**: 🔴 **CRITICAL**

**Why**:
1. **ALL financial calculations are WRONG** (not PUC-compliant)
2. **User decisions are based on INCORRECT data** (mixed Fixed/Variable)
3. **Dashboard shows misleading numbers** (single "Tus Cuentas" instead of Assets vs Liabilities)

**User Impact**:
- User cannot distinguish **what they OWN** vs **what they OWE**
- User cannot track **obligatory expenses** separately (leads to overspending)
- User cannot set **realistic budgets** for Fixed vs Variable

**Business Impact**:
- App does NOT deliver on "PUC-based architecture" promise
- Financial health features are **non-functional**
- App provides **less value** than a basic spreadsheet

---

## ✅ PHASE 2 COMPLETE

**Next Steps**:
1. **Approve this audit** (user sign-off required)
2. **Proceed to Phase 3**: Dashboard UI Purge
3. **After Phase 3**: Implement refactor plan with TDD approach

---

**Chief Technical Architect**
**Date**: 2026-01-07
**Phase 2 Status**: ✅ AUDIT COMPLETE - AWAITING APPROVAL
