import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Tipo de categoría según la taxonomía financiera
enum CategoryType {
  /// Activos - "Lo que Tengo"
  asset,

  /// Pasivos - "Lo que Debo"
  liability,

  /// Ingresos - "Lo que Entra"
  income,

  /// Gastos - "Lo que Sale"
  expense,
}

/// Entidad de Categoría inmutable
/// Representa una categoría en la taxonomía financiera jerárquica
@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    String? icon,
    required CategoryType type,
    String? parentId,
    @Default(0) int level,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    @Default(false) bool isSystem,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  /// Verifica si es una categoría raíz (nivel 0)
  bool get isRoot => level == 0;

  /// Verifica si tiene padre
  bool get hasParent => parentId != null;

  /// Nombre amigable del tipo
  String get typeName {
    switch (type) {
      case CategoryType.asset:
        return 'Lo que Tengo';
      case CategoryType.liability:
        return 'Lo que Debo';
      case CategoryType.income:
        return 'Lo que Entra';
      case CategoryType.expense:
        return 'Lo que Sale';
    }
  }
}
