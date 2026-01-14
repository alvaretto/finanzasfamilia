import 'categories/category_tree_dto.dart';

/// Modelo para representar un nodo del árbol de categorías.
///
/// Usado para construir una estructura jerárquica de categorías
/// que facilita la navegación y selección en la UI.
class CategoryTreeNode {
  CategoryTreeNode({
    required this.category,
    this.children = const [],
  });

  final CategoryTreeDto category;
  final List<CategoryTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  /// Obtiene la ruta completa de la categoría (ej: "Gastos > Alimentación > Mercado")
  String getPath(List<CategoryTreeDto> allCategories) {
    final parts = <String>[];
    CategoryTreeDto? current = category;

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

/// Servicio para construir árboles de categorías.
///
/// Contiene lógica pura sin dependencias de framework ni capa de datos.
class CategoryTreeBuilder {
  const CategoryTreeBuilder();

  /// Construye el árbol de categorías a partir de una lista plana
  List<CategoryTreeNode> buildTree(
    List<CategoryTreeDto> categories, {
    String? parentId,
  }) {
    final children = categories
        .where((c) => c.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return children.map((category) {
      return CategoryTreeNode(
        category: category,
        children: buildTree(categories, parentId: category.id),
      );
    }).toList();
  }

  /// Filtra solo las categorías hoja (sin hijos)
  List<CategoryTreeDto> getLeafCategories(List<CategoryTreeDto> categories) {
    return categories.where((c) {
      return !categories.any((other) => other.parentId == c.id);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Busca categorías por nombre
  List<CategoryTreeDto> searchByName(
    List<CategoryTreeDto> categories,
    String query,
  ) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return categories
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
