import 'category_expense.dart';

/// Grupo de gastos agrupados por categoría maestra
class ExpenseGroup {
  final String masterCategoryId;
  final String masterCategoryName;
  final String? icon;
  final double totalAmount;
  final List<CategoryExpense> subcategories;

  const ExpenseGroup({
    required this.masterCategoryId,
    required this.masterCategoryName,
    this.icon,
    required this.totalAmount,
    required this.subcategories,
  });
}
