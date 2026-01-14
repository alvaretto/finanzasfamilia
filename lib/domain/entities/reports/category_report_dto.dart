/// DTO para datos de categoría en reportes
class CategoryReportDto {
  final String id;
  final String name;
  final String type; // 'asset', 'liability', 'income', 'expense'

  const CategoryReportDto({
    required this.id,
    required this.name,
    required this.type,
  });
}
