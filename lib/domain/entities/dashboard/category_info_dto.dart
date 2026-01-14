/// DTO liviano para información de categoría en Dashboard.
/// Contiene solo los campos necesarios para cálculos y presentación.
class CategoryInfoDto {
  final String id;
  final String name;
  final String? icon;
  final String type; // 'asset', 'liability', 'income', 'expense'
  final String? parentId;
  final int level;

  const CategoryInfoDto({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    this.parentId,
    required this.level,
  });
}
