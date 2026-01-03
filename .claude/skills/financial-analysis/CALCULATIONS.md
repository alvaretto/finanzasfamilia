# Calculos Financieros

## Formulas Principales

### 1. Patrimonio Neto (Net Worth)

```
Patrimonio Neto = Total Activos - Total Pasivos
```

```dart
double netWorth(List<AccountModel> accounts) {
  double assets = 0;
  double liabilities = 0;

  for (final account in accounts) {
    if (account.type.isAsset) {
      assets += account.balance;
    } else if (account.type.isLiability) {
      liabilities += account.balance.abs();
    }
  }

  return assets - liabilities;
}
```

### 2. Tasa de Ahorro

```
Tasa de Ahorro = (Ingresos - Gastos) / Ingresos * 100
```

```dart
double savingsRate(double income, double expenses) {
  if (income <= 0) return 0;
  final rate = (income - expenses) / income * 100;
  return rate.clamp(-100, 100); // Permitir negativo (gastando mas de lo que gana)
}
```

**Interpretacion:**
- > 20%: Excelente
- 10-20%: Bueno
- 0-10%: Mejorable
- < 0%: Problematico

### 3. Ratio de Gastos por Categoria

```
% Categoria = Gasto en Categoria / Total Gastos * 100
```

```dart
Map<String, double> categoryPercentages(List<Transaction> expenses) {
  final total = expenses.fold(0.0, (sum, t) => sum + t.amount);
  if (total == 0) return {};

  final byCategory = <String, double>{};
  for (final tx in expenses) {
    final cat = tx.categoryName ?? 'Sin categoria';
    byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
  }

  return byCategory.map((k, v) => MapEntry(k, v / total * 100));
}
```

### 4. Progreso de Meta

```
% Completado = Monto Actual / Monto Objetivo * 100
```

```dart
double goalProgress(GoalModel goal) {
  if (goal.targetAmount <= 0) return 0; // Evitar division por cero
  final progress = goal.currentAmount / goal.targetAmount * 100;
  return progress.clamp(0, 100);
}
```

### 5. Varianza de Presupuesto

```
Varianza = Presupuesto - Gastado
Varianza % = (Presupuesto - Gastado) / Presupuesto * 100
```

```dart
({double amount, double percent}) budgetVariance(BudgetModel budget) {
  final variance = budget.amount - budget.spent;
  final percent = budget.amount > 0
    ? variance / budget.amount * 100
    : 0.0;

  return (amount: variance, percent: percent);
}
```

**Interpretacion:**
- Positivo: Bajo presupuesto (bien)
- Negativo: Sobre presupuesto (alerta)

### 6. Dias para Alcanzar Meta

```
Dias = (Objetivo - Actual) / Ahorro Promedio Diario
```

```dart
int? daysToGoal(GoalModel goal, double avgDailySavings) {
  if (avgDailySavings <= 0) return null; // Imposible
  if (goal.isCompleted) return 0;

  final remaining = goal.targetAmount - goal.currentAmount;
  return (remaining / avgDailySavings).ceil();
}
```

### 7. Utilizacion de Credito

```
% Utilizacion = Deuda / Limite de Credito * 100
```

```dart
double creditUtilization(AccountModel creditCard) {
  if (creditCard.creditLimit == null || creditCard.creditLimit! <= 0) {
    return 0;
  }
  final debt = creditCard.balance.abs();
  return (debt / creditCard.creditLimit! * 100).clamp(0, 100);
}
```

**Interpretacion:**
- < 30%: Excelente
- 30-50%: Aceptable
- > 50%: Alto riesgo

## Calculos de Periodo

### Ingresos/Gastos por Periodo

```dart
({double income, double expenses}) periodTotals(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
) {
  final filtered = transactions.where(
    (t) => t.date.isAfter(start) && t.date.isBefore(end),
  );

  double income = 0;
  double expenses = 0;

  for (final tx in filtered) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else if (tx.type == TransactionType.expense) {
      expenses += tx.amount;
    }
  }

  return (income: income, expenses: expenses);
}
```

### Promedio Movil (7 dias)

```dart
List<double> movingAverage(List<double> values, {int window = 7}) {
  if (values.length < window) return values;

  return List.generate(
    values.length - window + 1,
    (i) {
      final slice = values.sublist(i, i + window);
      return slice.reduce((a, b) => a + b) / window;
    },
  );
}
```

## Manejo de Edge Cases

```dart
// Siempre verificar division por cero
double safePercent(double part, double total) {
  if (total == 0) return 0;
  return part / total * 100;
}

// Redondear para display
String formatPercent(double value) {
  return '${value.toStringAsFixed(1)}%';
}

// Formatear moneda
String formatCurrency(double amount, String currency) {
  final formatter = NumberFormat.currency(
    symbol: currency == 'MXN' ? '\$' : currency,
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
```
