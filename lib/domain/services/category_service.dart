import '../exceptions/accounting_exceptions.dart';
import '../repositories/category_repository.dart';

/// Servicio de dominio para operaciones de categorías.
/// Contiene lógica de negocio que protege la integridad jerárquica.
class CategoryService {
  final CategoryRepository categoryRepository;

  CategoryService({required this.categoryRepository});

  /// Valida si una categoría puede ser eliminada.
  ///
  /// Throws [CategoryHasChildrenException] si la categoría tiene subcategorías.
  /// Throws [SystemCategoryException] si la categoría es del sistema.
  Future<void> validateCategoryDeletion(String categoryId) async {
    final category = await categoryRepository.getCategoryById(categoryId);
    if (category == null) {
      throw StateError('La categoría no existe: $categoryId');
    }

    // No permitir eliminar categorías del sistema
    if (category.isSystem) {
      throw SystemCategoryException(categoryName: category.name);
    }

    // No permitir eliminar categorías con hijos
    final childCount = await categoryRepository.countChildren(categoryId);
    if (childCount > 0) {
      throw CategoryHasChildrenException(
        categoryName: category.name,
        childCount: childCount,
      );
    }
  }

  /// Elimina una categoría después de validar que puede ser eliminada.
  ///
  /// Throws [CategoryHasChildrenException] si la categoría tiene subcategorías.
  /// Throws [SystemCategoryException] si la categoría es del sistema.
  Future<void> deleteCategory(String categoryId) async {
    await validateCategoryDeletion(categoryId);
    await categoryRepository.deleteCategory(categoryId);
  }
}
