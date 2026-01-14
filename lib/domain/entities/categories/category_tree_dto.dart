/// DTO para categoría usada en la construcción del árbol.
/// Contiene todos los campos necesarios para la jerarquía.
class CategoryTreeDto {
  final String id;
  final String name;
  final String? icon;
  final String type;
  final String? parentId;
  final int level;
  final int sortOrder;

  const CategoryTreeDto({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    this.parentId,
    required this.level,
    required this.sortOrder,
  });
}
