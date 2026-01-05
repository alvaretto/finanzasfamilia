import '../../features/transactions/domain/models/transaction_model.dart';

/// Utilidad para manejar jerarquía de categorías (2 niveles)
class CategoryHierarchyUtils {
  /// Obtener categorías principales (sin padre)
  static List<CategoryModel> getRootCategories(List<CategoryModel> all) {
    return all.where((c) => c.parentId == null).toList();
  }

  /// Obtener subcategorías de una categoría (nivel 1)
  static List<CategoryModel> getSubcategories(
    List<CategoryModel> all,
    int parentId,
  ) {
    return all.where((c) => c.parentId == parentId).toList();
  }

  /// Obtener sub-subcategorías de una subcategoría (nivel 2)
  static List<CategoryModel> getSubSubcategories(
    List<CategoryModel> all,
    int subcategoryId,
  ) {
    return all.where((c) => c.parentId == subcategoryId).toList();
  }

  /// Verificar si una categoría tiene hijos
  static bool hasChildren(List<CategoryModel> all, int categoryId) {
    return all.any((c) => c.parentId == categoryId);
  }

  /// Obtener nivel de una categoría (0: raíz, 1: subcategoría, 2: sub-subcategoría)
  static int getCategoryLevel(List<CategoryModel> all, CategoryModel category) {
    if (category.parentId == null) return 0;

    final parent = all.firstWhere(
      (c) => c.id == category.parentId,
      orElse: () => category,
    );

    if (parent.parentId == null) return 1;
    return 2;
  }

  /// Obtener path completo de una categoría (raíz > sub > subsub)
  static String getCategoryPath(List<CategoryModel> all, CategoryModel category) {
    if (category.parentId == null) {
      return category.name;
    }

    final parent = all.firstWhere(
      (c) => c.id == category.parentId,
      orElse: () => category,
    );

    if (parent.parentId == null) {
      return '${parent.name} > ${category.name}';
    }

    final grandparent = all.firstWhere(
      (c) => c.id == parent.parentId,
      orElse: () => parent,
    );

    return '${grandparent.name} > ${parent.name} > ${category.name}';
  }

  /// Obtener categoría raíz de una categoría (sube hasta el nivel 0)
  static CategoryModel getRootCategory(
    List<CategoryModel> all,
    CategoryModel category,
  ) {
    if (category.parentId == null) return category;

    final parent = all.firstWhere(
      (c) => c.id == category.parentId,
      orElse: () => category,
    );

    if (parent.parentId == null) return parent;

    final grandparent = all.firstWhere(
      (c) => c.id == parent.parentId,
      orElse: () => parent,
    );

    return grandparent;
  }

  /// Construir árbol jerárquico para UI
  static List<CategoryTreeNode> buildTree(List<CategoryModel> all, String type) {
    final filtered = all.where((c) => c.type == type).toList();
    final roots = getRootCategories(filtered);

    return roots.map((root) {
      final level1Children = getSubcategories(filtered, root.id);

      final level1Nodes = level1Children.map((level1) {
        final level2Children = getSubSubcategories(filtered, level1.id);

        final level2Nodes = level2Children.map((level2) {
          return CategoryTreeNode(
            category: level2,
            children: [],
            level: 2,
          );
        }).toList();

        return CategoryTreeNode(
          category: level1,
          children: level2Nodes,
          level: 1,
        );
      }).toList();

      return CategoryTreeNode(
        category: root,
        children: level1Nodes,
        level: 0,
      );
    }).toList();
  }

  /// Aplanar árbol para lista lineal con indentación
  static List<FlatCategoryItem> flattenTree(List<CategoryTreeNode> tree) {
    final items = <FlatCategoryItem>[];

    for (final node in tree) {
      items.add(FlatCategoryItem(
        category: node.category,
        level: node.level,
        hasChildren: node.children.isNotEmpty,
      ));

      for (final child in node.children) {
        items.add(FlatCategoryItem(
          category: child.category,
          level: child.level,
          hasChildren: child.children.isNotEmpty,
        ));

        for (final grandchild in child.children) {
          items.add(FlatCategoryItem(
            category: grandchild.category,
            level: grandchild.level,
            hasChildren: false,
          ));
        }
      }
    }

    return items;
  }

  /// Validar que no se cree una jerarquía circular
  static bool isValidParent(
    List<CategoryModel> all,
    CategoryModel category,
    int? newParentId,
  ) {
    if (newParentId == null) return true;
    if (newParentId == category.id) return false; // No puede ser su propio padre

    // Verificar que el nuevo padre no sea descendiente de esta categoría
    final descendants = getSubcategories(all, category.id);
    for (final desc in descendants) {
      if (desc.id == newParentId) return false;
      final subDescendants = getSubSubcategories(all, desc.id);
      if (subDescendants.any((sd) => sd.id == newParentId)) return false;
    }

    // Verificar que el nuevo padre no esté en el nivel 2
    final parent = all.firstWhere(
      (c) => c.id == newParentId,
      orElse: () => category,
    );

    if (parent.parentId != null) {
      final grandparent = all.firstWhere(
        (c) => c.id == parent.parentId,
        orElse: () => parent,
      );
      if (grandparent.parentId != null) {
        return false; // Nivel 3 no permitido
      }
    }

    return true;
  }
}

/// Nodo de árbol de categorías
class CategoryTreeNode {
  final CategoryModel category;
  final List<CategoryTreeNode> children;
  final int level;

  CategoryTreeNode({
    required this.category,
    required this.children,
    required this.level,
  });
}

/// Item aplanado de categoría para listas lineales
class FlatCategoryItem {
  final CategoryModel category;
  final int level;
  final bool hasChildren;

  FlatCategoryItem({
    required this.category,
    required this.level,
    required this.hasChildren,
  });

  /// Indentación en pixels
  double get indentation => level * 24.0;

  /// Emoji prefix según nivel
  String get levelPrefix {
    switch (level) {
      case 0:
        return '';
      case 1:
        return '  └─ ';
      case 2:
        return '    └─ ';
      default:
        return '';
    }
  }

  /// Display name con indentación
  String get displayName => '$levelPrefix${category.name}';
}
