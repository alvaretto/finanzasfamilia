/// Gasto por categoría
class CategoryExpense {
  final String categoryId;
  final String categoryName;
  final String? icon;
  final double amount;
  final double percentage;

  const CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    required this.amount,
    required this.percentage,
  });
}
