/// Análisis de gastos hormiga (gastos pequeños y frecuentes)
///
/// Los gastos hormiga son compras pequeñas (< $20,000 COP) que individualmente
/// parecen insignificantes, pero que sumadas pueden representar una cantidad
/// considerable al mes.
class AntExpenseAnalysis {
  final Map<String, AntExpenseCategory> categories;
  final double totalAmount;
  final int totalTransactions;

  const AntExpenseAnalysis({
    required this.categories,
    required this.totalAmount,
    required this.totalTransactions,
  });

  /// Nivel de impacto de los gastos hormiga
  AntExpenseImpact get impact {
    if (totalAmount > 200000) return AntExpenseImpact.high;
    if (totalAmount > 100000) return AntExpenseImpact.medium;
    if (totalAmount > 50000) return AntExpenseImpact.low;
    return AntExpenseImpact.none;
  }

  /// Mensaje sobre el impacto
  String get impactMessage {
    switch (impact) {
      case AntExpenseImpact.high:
        return '🐜 GASTOS HORMIGA DETECTADOS';
      case AntExpenseImpact.medium:
        return '⚠️ Gastos hormiga moderados';
      case AntExpenseImpact.low:
        return '📊 Algunos gastos hormiga';
      case AntExpenseImpact.none:
        return '✅ Sin gastos hormiga significativos';
    }
  }

  /// Ahorro potencial si reduces 50%
  double get potentialSavings => totalAmount * 0.5;

  /// Top 3 categorías con más gastos hormiga
  List<AntExpenseCategory> get topCategories {
    final sorted = categories.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return sorted.take(3).toList();
  }

  /// Mensaje completo con recomendaciones
  String get fullMessage {
    if (impact == AntExpenseImpact.none) {
      return '✅ No tienes gastos hormiga significativos este mes';
    }

    final top = topCategories;
    final topList = top.map((cat) {
      return '• ${cat.name}: \$${cat.total.toStringAsFixed(0)} (${cat.frequency} veces)';
    }).join('\n');

    return '''
$impactMessage

Pequeñas compras que suman: \$${totalAmount.toStringAsFixed(0)}

Las más frecuentes:
$topList

💡 Si reduces estos gastos, podrías ahorrar
\$${potentialSavings.toStringAsFixed(0)} al mes
''';
  }
}

/// Categoría de gastos hormiga
class AntExpenseCategory {
  final String name;
  final double total;
  final int frequency;
  final double average;

  const AntExpenseCategory({
    required this.name,
    required this.total,
    required this.frequency,
    required this.average,
  });

  /// Impacto de esta categoría
  CategoryImpact get impact {
    if (total > 100000) return CategoryImpact.high;
    if (total > 50000) return CategoryImpact.medium;
    return CategoryImpact.low;
  }
}

/// Nivel de impacto de gastos hormiga
enum AntExpenseImpact {
  none, // < 50,000
  low, // 50,000 - 100,000
  medium, // 100,000 - 200,000
  high, // > 200,000
}

/// Impacto de categoría individual
enum CategoryImpact {
  low, // < 50,000
  medium, // 50,000 - 100,000
  high, // > 100,000
}
