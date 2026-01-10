import '../../data/local/database.dart';

/// Modelo para representar un nodo del árbol de categorías
///
/// Usado para construir una estructura jerárquica de categorías
/// que facilita la navegación y selección en la UI.
class CategoryTreeNode {
  CategoryTreeNode({
    required this.category,
    this.children = const [],
  });

  final CategoryEntry category;
  final List<CategoryTreeNode> children;

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  /// Obtiene la ruta completa de la categoría (ej: "Gastos > Alimentación > Mercado")
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

/// Servicio para construir árboles de categorías
///
/// Contiene lógica pura sin dependencias de framework.
class CategoryTreeBuilder {
  const CategoryTreeBuilder();

  /// Construye el árbol de categorías a partir de una lista plana
  List<CategoryTreeNode> buildTree(
    List<CategoryEntry> categories, {
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
  List<CategoryEntry> getLeafCategories(List<CategoryEntry> categories) {
    return categories.where((c) {
      return !categories.any((other) => other.parentId == c.id);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Busca categorías por nombre
  List<CategoryEntry> searchByName(
    List<CategoryEntry> categories,
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
