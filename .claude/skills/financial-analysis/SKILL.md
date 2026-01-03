---
name: financial-analysis
description: Analiza datos financieros, genera reportes, calcula metricas como patrimonio neto, tasa de ahorro, y varianza de presupuesto. Usar para analizar transacciones, crear reportes financieros, o calcular ratios financieros.
---

# Financial Analysis

Skill para analisis financiero en Finanzas Familiares.

## Metricas Principales

### Patrimonio Neto
```dart
double calculateNetWorth(List<AccountModel> accounts) {
  final assets = accounts
    .where((a) => a.type.isAsset)
    .fold(0.0, (sum, a) => sum + a.balance);

  final liabilities = accounts
    .where((a) => a.type.isLiability)
    .fold(0.0, (sum, a) => sum + a.balance.abs());

  return assets - liabilities;
}
```

### Tasa de Ahorro
```dart
double calculateSavingsRate(double income, double expenses) {
  if (income <= 0) return 0;
  return ((income - expenses) / income * 100).clamp(0, 100);
}
```

### Credito Disponible
```dart
double getAvailableCredit(AccountModel creditCard) {
  if (creditCard.creditLimit == null) return 0;
  return creditCard.creditLimit! + creditCard.balance; // balance es negativo
}
```

## Clasificacion de Cuentas

| Tipo | isAsset | isLiability | Balance tipico |
|------|---------|-------------|----------------|
| `bank` | true | false | Positivo |
| `cash` | true | false | Positivo |
| `savings` | true | false | Positivo |
| `investment` | true | false | Positivo |
| `credit` | false | true | Negativo |
| `loan` | false | true | Negativo |
| `payable` | false | true | Negativo |
| `receivable` | - | - | Positivo (por cobrar) |

## Archivos Clave

| Archivo | Funcion |
|---------|---------|
| `account_model.dart` | Tipos de cuenta, isAsset/isLiability |
| `budget_model.dart` | Calculo de % gastado, excedido |
| `goal_model.dart` | Progreso hacia metas |
| `reports_screen.dart` | Visualizaciones |

## Documentacion Detallada

- [CALCULATIONS.md](CALCULATIONS.md) - Formulas y calculos financieros
- [REPORTS.md](REPORTS.md) - Tipos de reportes disponibles
- [CATEGORIES.md](CATEGORIES.md) - Taxonomia de categorias

## Ejemplo de Analisis Mensual

```dart
Map<String, dynamic> analyzeMonth(List<Transaction> transactions) {
  final income = transactions
    .where((t) => t.type == TransactionType.income)
    .fold(0.0, (sum, t) => sum + t.amount);

  final expenses = transactions
    .where((t) => t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);

  final byCategory = <String, double>{};
  for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
    final cat = t.categoryName ?? 'Sin categoria';
    byCategory[cat] = (byCategory[cat] ?? 0) + t.amount;
  }

  return {
    'income': income,
    'expenses': expenses,
    'balance': income - expenses,
    'savingsRate': calculateSavingsRate(income, expenses),
    'byCategory': byCategory,
  };
}
```
