import 'package:drift/drift.dart';

import '../../domain/repositories/category_repository.dart';
import '../local/database.dart';

/// Implementación concreta de CategoryRepository usando Drift.
class DriftCategoryRepository implements CategoryRepository {
  final AppDatabase _db;

  DriftCategoryRepository(this._db);

  @override
  Future<CategoryData?> getCategoryById(String id) async {
    final entry = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return null;
    return _toCategoryData(entry);
  }

  @override
  Future<List<CategoryData>> getAllCategories() async {
    final entries = await _db.select(_db.categories).get();
    return entries.map(_toCategoryData).toList();
  }

  @override
  Future<void> insertCategory(CategoryData category) async {
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: category.id,
          name: category.name,
          type: category.type,
          parentId: Value(category.parentId),
          level: Value(category.level),
          isSystem: Value(category.isSystem),
          createdAt: Value(category.createdAt),
          updatedAt: Value(category.updatedAt),
        ));
  }

  CategoryData _toCategoryData(CategoryEntry entry) {
    return CategoryData(
      id: entry.id,
      name: entry.name,
      type: entry.type,
      parentId: entry.parentId,
      level: entry.level,
      isSystem: entry.isSystem,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
