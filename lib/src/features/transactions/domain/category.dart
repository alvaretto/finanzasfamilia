import 'package:uuid/uuid.dart';

enum CategoryType {
  income,
  expense,
}

class Category {
  final String id;
  final String? userId;
  final String? parentId;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;

  // Relaciones (no persistidas directamente)
  final List<Category> subcategories;
  final Category? parent;

  Category({
    String? id,
    this.userId,
    this.parentId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isSystem = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    this.subcategories = const [],
    this.parent,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    String? parentId,
    String? name,
    CategoryType? type,
    String? icon,
    String? color,
    int? sortOrder,
    List<Category>? subcategories,
    Category? parent,
  }) {
    return Category(
      id: id,
      userId: userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      subcategories: subcategories ?? this.subcategories,
      parent: parent ?? this.parent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'is_system': isSystem ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      parentId: map['parent_id'] as String?,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isSystem: map['is_system'] == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Path completo de la categoría (ej: "Alimentación > Mercado > Frutas")
  String get fullPath {
    if (parent != null) {
      return '${parent!.fullPath} > $name';
    }
    return name;
  }

  /// Profundidad en el árbol (0 = raíz)
  int get depth {
    if (parent == null) return 0;
    return parent!.depth + 1;
  }

  /// Es categoría hoja (sin subcategorías)
  bool get isLeaf => subcategories.isEmpty;
}

/// Categorías predefinidas del sistema
class SystemCategories {
  static List<Category> get expenses => [
    // Nivel 1 - Categorías principales
    Category(id: 'cat_taxes', name: 'Impuestos', type: CategoryType.expense, icon: '🏛️', isSystem: true, sortOrder: 1),
    Category(id: 'cat_services', name: 'Servicios', type: CategoryType.expense, icon: '💡', isSystem: true, sortOrder: 2),
    Category(id: 'cat_food', name: 'Alimentación', type: CategoryType.expense, icon: '🍽️', isSystem: true, sortOrder: 3),
    Category(id: 'cat_transport', name: 'Transporte', type: CategoryType.expense, icon: '🚗', isSystem: true, sortOrder: 4),
    Category(id: 'cat_entertainment', name: 'Entretenimiento', type: CategoryType.expense, icon: '🎬', isSystem: true, sortOrder: 5),
    Category(id: 'cat_health', name: 'Salud', type: CategoryType.expense, icon: '🏥', isSystem: true, sortOrder: 6),
    Category(id: 'cat_education', name: 'Educación', type: CategoryType.expense, icon: '📚', isSystem: true, sortOrder: 7),
    Category(id: 'cat_cleaning', name: 'Aseo', type: CategoryType.expense, icon: '🧹', isSystem: true, sortOrder: 8),
    Category(id: 'cat_other', name: 'Otros', type: CategoryType.expense, icon: '📦', isSystem: true, sortOrder: 9),

    // Nivel 2 - Alimentación
    Category(id: 'cat_grocery', name: 'Mercado', type: CategoryType.expense, icon: '🛒', parentId: 'cat_food', isSystem: true),
    Category(id: 'cat_restaurants', name: 'Restaurantes', type: CategoryType.expense, icon: '🍴', parentId: 'cat_food', isSystem: true),
    Category(id: 'cat_delivery', name: 'Domicilios', type: CategoryType.expense, icon: '🛵', parentId: 'cat_food', isSystem: true),

    // Nivel 3 - Mercado (granularidad educativa)
    Category(id: 'cat_fruits', name: 'Frutas', type: CategoryType.expense, icon: '🍎', parentId: 'cat_grocery', isSystem: true),
    Category(id: 'cat_vegetables', name: 'Verduras', type: CategoryType.expense, icon: '🥬', parentId: 'cat_grocery', isSystem: true),
    Category(id: 'cat_meat', name: 'Cárnicos', type: CategoryType.expense, icon: '🥩', parentId: 'cat_grocery', isSystem: true),
    Category(id: 'cat_dairy', name: 'Lácteos', type: CategoryType.expense, icon: '🥛', parentId: 'cat_grocery', isSystem: true),
    Category(id: 'cat_grains', name: 'Granos', type: CategoryType.expense, icon: '🌾', parentId: 'cat_grocery', isSystem: true),
    Category(id: 'cat_snacks', name: 'Mecato', type: CategoryType.expense, icon: '🍿', parentId: 'cat_grocery', isSystem: true),

    // Servicios
    Category(id: 'cat_electricity', name: 'EDEQ', type: CategoryType.expense, icon: '⚡', parentId: 'cat_services', isSystem: true),
    Category(id: 'cat_water', name: 'EPA', type: CategoryType.expense, icon: '💧', parentId: 'cat_services', isSystem: true),
    Category(id: 'cat_gas', name: 'EfiGas', type: CategoryType.expense, icon: '🔥', parentId: 'cat_services', isSystem: true),
    Category(id: 'cat_internet', name: 'Internet', type: CategoryType.expense, icon: '📶', parentId: 'cat_services', isSystem: true),
    Category(id: 'cat_admin', name: 'Administración', type: CategoryType.expense, icon: '🏢', parentId: 'cat_services', isSystem: true),

    // Impuestos
    Category(id: 'cat_tax_vehicle', name: 'Vehicular', type: CategoryType.expense, icon: '🚙', parentId: 'cat_taxes', isSystem: true),
    Category(id: 'cat_tax_property', name: 'Predial', type: CategoryType.expense, icon: '🏠', parentId: 'cat_taxes', isSystem: true),
    Category(id: 'cat_tax_income', name: 'Renta', type: CategoryType.expense, icon: '📋', parentId: 'cat_taxes', isSystem: true),
    Category(id: 'cat_tax_4x1000', name: '4x1000', type: CategoryType.expense, icon: '💸', parentId: 'cat_taxes', isSystem: true),

    // Transporte
    Category(id: 'cat_fuel', name: 'Gasolina', type: CategoryType.expense, icon: '⛽', parentId: 'cat_transport', isSystem: true),
    Category(id: 'cat_public_transport', name: 'Transporte Público', type: CategoryType.expense, icon: '🚌', parentId: 'cat_transport', isSystem: true),
    Category(id: 'cat_maintenance', name: 'Mantenimiento', type: CategoryType.expense, icon: '🔧', parentId: 'cat_transport', isSystem: true),
  ];

  static List<Category> get incomes => [
    Category(id: 'cat_salary', name: 'Salario', type: CategoryType.income, icon: '💰', isSystem: true, sortOrder: 1),
    Category(id: 'cat_sales', name: 'Ventas', type: CategoryType.income, icon: '🛒', isSystem: true, sortOrder: 2),
    Category(id: 'cat_investments', name: 'Rendimientos', type: CategoryType.income, icon: '📈', isSystem: true, sortOrder: 3),
    Category(id: 'cat_other_income', name: 'Otros Ingresos', type: CategoryType.income, icon: '💵', isSystem: true, sortOrder: 4),
  ];

  static List<Category> get all => [...expenses, ...incomes];
}
