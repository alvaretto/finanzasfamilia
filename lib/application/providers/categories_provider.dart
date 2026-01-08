import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';
import 'database_provider.dart';

part 'categories_provider.g.dart';

/// Estado de las categorías
@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  @override
  Future<List<CategoryEntry>> build() async {
    final dao = ref.watch(categoriesDaoProvider);
    return dao.getAllCategories();
  }

  /// Recarga las categorías desde la base de datos
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dao = ref.read(categoriesDaoProvider);
      return dao.getAllCategories();
    });
  }
}

/// Provider de categorías por tipo
@riverpod
Future<List<CategoryEntry>> categoriesByType(
  CategoriesByTypeRef ref,
  String type,
) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getCategoriesByType(type);
}

/// Provider de categorías de gastos (para el semáforo)
@riverpod
Future<List<CategoryEntry>> expenseCategories(ExpenseCategoriesRef ref) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getExpenseCategories();
}

/// Provider de categorías raíz
@riverpod
Future<List<CategoryEntry>> rootCategories(RootCategoriesRef ref) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getRootCategories();
}

/// Provider de subcategorías de una categoría padre
@riverpod
Future<List<CategoryEntry>> childCategories(
  ChildCategoriesRef ref,
  String parentId,
) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getChildCategories(parentId);
}

/// Stream de categorías (reactivo)
@riverpod
Stream<List<CategoryEntry>> categoriesStream(CategoriesStreamRef ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.watchAllCategories();
}
