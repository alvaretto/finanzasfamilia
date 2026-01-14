/// Interfaz de repositorio para operaciones de categorías.
/// Define el contrato que la capa de dominio necesita sin depender de Drift.
abstract class CategoryRepository {
  /// Obtiene una categoría por ID.
  Future<CategoryData?> getCategoryById(String id);

  /// Obtiene todas las categorías.
  Future<List<CategoryData>> getAllCategories();

  /// Obtiene las categorías hijas de una categoría padre.
  Future<List<CategoryData>> getChildCategories(String parentId);

  /// Cuenta cuántas categorías hijas tiene una categoría.
  Future<int> countChildren(String categoryId);

  /// Inserta una nueva categoría.
  Future<void> insertCategory(CategoryData category);

  /// Elimina una categoría por ID.
  Future<void> deleteCategory(String categoryId);
}

/// Modelo de datos de categoría para la capa de dominio.
/// Independiente de Drift.
class CategoryData {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final int level;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryData({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.level,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
  });
}
