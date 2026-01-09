import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Ref ref,
  String type,
) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getCategoriesByType(type);
}

/// Provider de categorías de gastos (para el semáforo)
@riverpod
Future<List<CategoryEntry>> expenseCategories(Ref ref) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getExpenseCategories();
}

/// Provider de categorías raíz
@riverpod
Future<List<CategoryEntry>> rootCategories(Ref ref) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getRootCategories();
}

/// Provider de subcategorías de una categoría padre
@riverpod
Future<List<CategoryEntry>> childCategories(
  Ref ref,
  String parentId,
) async {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.getChildCategories(parentId);
}

/// Stream de categorías (reactivo)
@riverpod
Stream<List<CategoryEntry>> categoriesStream(Ref ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.watchAllCategories();
}

/// Modelo para representar un nodo del árbol de categorías
class CategoryTreeNode {
  CategoryTreeNode({
    required this.category,
    this.children = const [],
  });

  final CategoryEntry category;
  final List<CategoryTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  /// Obtiene la ruta completa de la categoría
  String getPath(List<CategoryEntry> allCategories) {
    final parts = <String>[];
    CategoryEntry? current = category;

    while (current != null) {
      parts.insert(0, current.name);
      if (current.parentId != null) {
        current = allCategories
            .where((c) => c.id == current!.parentId)
            .firstOrNull;
      } else {
        current = null;
      }
    }

    return parts.join(' > ');
  }
}

/// Provider que construye el árbol de categorías por tipo
@riverpod
Future<List<CategoryTreeNode>> categoryTree(
  Ref ref,
  String type,
) async {
  final categories = await ref.watch(categoriesByTypeProvider(type).future);
  return _buildTree(categories, null);
}

/// Construye el árbol recursivamente
List<CategoryTreeNode> _buildTree(
  List<CategoryEntry> categories,
  String? parentId,
) {
  final children = categories
      .where((c) => c.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return children.map((category) {
    return CategoryTreeNode(
      category: category,
      children: _buildTree(categories, category.id),
    );
  }).toList();
}

/// Provider para obtener categorías hoja (sin hijos) de un tipo
@riverpod
Future<List<CategoryEntry>> leafCategories(
  Ref ref,
  String type,
) async {
  final categories = await ref.watch(categoriesByTypeProvider(type).future);

  // Filtrar solo las que no tienen hijos
  return categories.where((c) {
    return !categories.any((other) => other.parentId == c.id);
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

/// Provider para buscar categorías por nombre
@riverpod
Future<List<CategoryEntry>> searchCategories(
  Ref ref,
  String type,
  String query,
) async {
  if (query.isEmpty) return [];

  final categories = await ref.watch(categoriesByTypeProvider(type).future);
  final lowerQuery = query.toLowerCase();

  return categories
      .where((c) => c.name.toLowerCase().contains(lowerQuery))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}
