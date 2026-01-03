# Taxonomia de Categorias

## Categorias de Gasto (15)

| ID | Nombre | Icono | Subcategorias |
|----|--------|-------|---------------|
| 1 | Alimentacion | restaurant | Supermercado, Restaurantes, Delivery, Cafe |
| 2 | Transporte | directions_car | Gasolina, Transporte publico, Taxi/Uber, Mantenimiento |
| 3 | Vivienda | home | Renta/Hipoteca, Servicios, Mantenimiento, Seguros |
| 4 | Servicios | bolt | Luz, Agua, Gas, Internet, Telefono |
| 5 | Salud | medical_services | Consultas, Medicinas, Seguros, Gimnasio |
| 6 | Educacion | school | Colegiaturas, Cursos, Libros, Materiales |
| 7 | Entretenimiento | movie | Streaming, Cine, Eventos, Hobbies |
| 8 | Ropa | checkroom | Vestimenta, Calzado, Accesorios |
| 9 | Cuidado Personal | spa | Higiene, Belleza, Peluqueria |
| 10 | Mascotas | pets | Comida, Veterinario, Accesorios |
| 11 | Regalos | card_giftcard | Cumpleanos, Navidad, Ocasiones |
| 12 | Suscripciones | subscriptions | Apps, Servicios, Membresias |
| 13 | Seguros | security | Auto, Vida, Gastos medicos |
| 14 | Impuestos | receipt_long | ISR, Predial, Tenencia |
| 15 | Otros Gastos | more_horiz | Miscelaneos |

## Categorias de Ingreso (6)

| ID | Nombre | Icono | Subcategorias |
|----|--------|-------|---------------|
| 101 | Salario | work | Nomina, Aguinaldo, Bonos |
| 102 | Freelance | laptop | Proyectos, Consultoria |
| 103 | Inversiones | trending_up | Dividendos, Intereses, Ganancias |
| 104 | Negocio | store | Ventas, Servicios |
| 105 | Regalos Recibidos | redeem | Cumpleanos, Herencias |
| 106 | Otros Ingresos | attach_money | Reembolsos, Devoluciones |

## Uso en Codigo

```dart
// Definicion en categories.dart
enum ExpenseCategory {
  alimentacion(1, 'Alimentacion', 'restaurant'),
  transporte(2, 'Transporte', 'directions_car'),
  vivienda(3, 'Vivienda', 'home'),
  // ...

  const ExpenseCategory(this.id, this.name, this.icon);

  final int id;
  final String name;
  final String icon;
}

// Obtener icono
IconData getCategoryIcon(int categoryId) {
  return switch (categoryId) {
    1 => Icons.restaurant,
    2 => Icons.directions_car,
    3 => Icons.home,
    // ...
    _ => Icons.category,
  };
}
```

## Asignacion de Presupuestos Sugeridos

Basado en la regla 50/30/20:

| Grupo | % del Ingreso | Categorias |
|-------|---------------|------------|
| Necesidades | 50% | Vivienda, Servicios, Alimentacion, Transporte, Salud |
| Deseos | 30% | Entretenimiento, Ropa, Cuidado Personal, Suscripciones |
| Ahorro/Deuda | 20% | Metas de ahorro, Pago de deudas |

```dart
Map<int, double> suggestBudgets(double monthlyIncome) {
  return {
    3: monthlyIncome * 0.30,  // Vivienda: 30%
    1: monthlyIncome * 0.10,  // Alimentacion: 10%
    2: monthlyIncome * 0.05,  // Transporte: 5%
    4: monthlyIncome * 0.05,  // Servicios: 5%
    7: monthlyIncome * 0.10,  // Entretenimiento: 10%
    // ... resto segun preferencias
  };
}
```

## Analisis por Categoria

```dart
List<CategoryAnalysis> analyzeCategoriesFromTransactions(
  List<Transaction> transactions,
) {
  final byCategory = <int, List<Transaction>>{};

  for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
    final catId = tx.categoryId ?? 0;
    byCategory.putIfAbsent(catId, () => []).add(tx);
  }

  return byCategory.entries.map((e) {
    final total = e.value.fold(0.0, (sum, t) => sum + t.amount);
    final count = e.value.length;
    return CategoryAnalysis(
      categoryId: e.key,
      total: total,
      count: count,
      average: total / count,
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total)); // Mayor a menor
}
```
