import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

/// Categorías de unidades de medida
enum UnitCategory {
  weight('weight', 'Peso', 'scale'),
  volume('volume', 'Volumen', 'water_drop'),
  length('length', 'Longitud', 'straighten'),
  unit('unit', 'Unidades', 'inventory_2');

  final String value;
  final String displayName;
  final String icon;

  const UnitCategory(this.value, this.displayName, this.icon);

  static UnitCategory fromValue(String value) {
    return UnitCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UnitCategory.unit,
    );
  }
}

/// Modelo de unidad de medida
@freezed
class UnitModel with _$UnitModel {
  const UnitModel._();

  const factory UnitModel({
    required String id,
    required String name,
    required String shortName,
    required String category,
    @Default(true) bool isSystem,
    DateTime? createdAt,
  }) = _UnitModel;

  factory UnitModel.fromJson(Map<String, dynamic> json) =>
      _$UnitModelFromJson(json);

  /// Categoría tipada
  UnitCategory get categoryEnum => UnitCategory.fromValue(category);

  /// Nombre para mostrar con abreviatura: "Kilogramo (kg)"
  String get displayNameWithShort => '$name ($shortName)';

  /// Crear desde registro de Drift
  factory UnitModel.fromDrift(dynamic row) {
    return UnitModel(
      id: row.id as String,
      name: row.name as String,
      shortName: row.shortName as String,
      category: row.category as String,
      isSystem: row.isSystem as bool? ?? true,
      createdAt: row.createdAt as DateTime?,
    );
  }
}
