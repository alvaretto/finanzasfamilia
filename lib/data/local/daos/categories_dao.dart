import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

/// DAO para operaciones CRUD de categorías
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Obtiene todas las categorías
  Future<List<CategoryEntry>> getAllCategories() => select(categories).get();

  /// Obtiene categorías por tipo (asset, liability, income, expense)
  Future<List<CategoryEntry>> getCategoriesByType(String type) {
    return (select(categories)..where((c) => c.type.equals(type))).get();
  }

  /// Obtiene categorías raíz (sin padre)
  Future<List<CategoryEntry>> getRootCategories() {
    return (select(categories)..where((c) => c.parentId.isNull())).get();
  }

  /// Obtiene hijos de una categoría
  Future<List<CategoryEntry>> getChildCategories(String parentId) {
    return (select(categories)..where((c) => c.parentId.equals(parentId))).get();
  }

  /// Obtiene una categoría por ID
  Future<CategoryEntry?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Inserta una categoría
  Future<void> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Inserta múltiples categorías
  Future<void> insertCategories(List<CategoriesCompanion> categoryList) {
    return batch((batch) {
      batch.insertAll(categories, categoryList);
    });
  }

  /// Actualiza una categoría
  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(CategoryEntry(
      id: category.id.value,
      name: category.name.value,
      icon: category.icon.value,
      type: category.type.value,
      parentId: category.parentId.value,
      level: category.level.value,
      sortOrder: category.sortOrder.value,
      isActive: category.isActive.value,
      isSystem: category.isSystem.value,
      createdAt: category.createdAt.value,
      updatedAt: DateTime.now(),
    ));
  }

  /// Elimina una categoría
  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  /// Stream de todas las categorías (reactivo)
  Stream<List<CategoryEntry>> watchAllCategories() => select(categories).watch();

  /// Stream de categorías por tipo
  Stream<List<CategoryEntry>> watchCategoriesByType(String type) {
    return (select(categories)..where((c) => c.type.equals(type))).watch();
  }

  /// Obtiene categorías de gastos con sus subcategorías (para el semáforo)
  Future<List<CategoryEntry>> getExpenseCategories() {
    return (select(categories)
          ..where((c) => c.type.equals('expense'))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }
}
