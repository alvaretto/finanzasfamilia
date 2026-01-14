import '../../domain/entities/categories/category_tree_dto.dart';
import '../local/database.dart';

/// Mappers para convertir Drift CategoryEntry a DTOs del árbol de categorías.
class CategoryTreeMappers {
  const CategoryTreeMappers._();

  /// Convierte CategoryEntry a CategoryTreeDto
  static CategoryTreeDto categoryToDto(CategoryEntry entry) {
    return CategoryTreeDto(
      id: entry.id,
      name: entry.name,
      icon: entry.icon,
      type: entry.type,
      parentId: entry.parentId,
      level: entry.level ?? 0,
      sortOrder: entry.sortOrder ?? 0,
    );
  }

  /// Convierte lista de CategoryEntry a lista de CategoryTreeDto
  static List<CategoryTreeDto> categoriesToDtoList(
      List<CategoryEntry> entries) {
    return entries.map(categoryToDto).toList();
  }
}
