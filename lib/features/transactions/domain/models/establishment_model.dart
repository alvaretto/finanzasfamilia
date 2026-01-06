import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/payment_enums.dart';

part 'establishment_model.freezed.dart';
part 'establishment_model.g.dart';

const _uuid = Uuid();

/// Modelo de establecimiento (lugar de compra)
@freezed
class EstablishmentModel with _$EstablishmentModel {
  const EstablishmentModel._();

  const factory EstablishmentModel({
    required String id,
    required String userId,
    required String name,
    String? address,
    String? phone,
    String? category,
    String? icon,
    @Default(0) int useCount,
    @Default(false) bool isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _EstablishmentModel;

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) =>
      _$EstablishmentModelFromJson(json);

  /// Crear nuevo establecimiento
  factory EstablishmentModel.create({
    required String userId,
    required String name,
    String? address,
    String? phone,
    String? category,
    String? icon,
  }) {
    return EstablishmentModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      address: address,
      phone: phone,
      category: category,
      icon: icon,
      useCount: 1,
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Categoría tipada
  EstablishmentCategory? get categoryEnum =>
      EstablishmentCategory.fromValue(category);

  /// Nombre para mostrar con dirección: "Supermercado Éxito - Calle 50"
  String get displayNameWithAddress {
    if (address != null && address!.isNotEmpty) {
      return '$name - $address';
    }
    return name;
  }

  /// Icono a mostrar (usa icono de categoría si no hay personalizado)
  String get displayIcon {
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    return categoryEnum?.icon ?? 'place';
  }

  /// Crear desde registro de Drift
  factory EstablishmentModel.fromDrift(dynamic row) {
    return EstablishmentModel(
      id: row.id as String,
      userId: row.userId as String,
      name: row.name as String,
      address: row.address as String?,
      phone: row.phone as String?,
      category: row.category as String?,
      icon: row.icon as String?,
      useCount: row.useCount as int? ?? 0,
      isSynced: row.isSynced as bool? ?? false,
      createdAt: row.createdAt as DateTime?,
      updatedAt: row.updatedAt as DateTime?,
    );
  }

  /// Convierte a Map para inserción en Drift
  Map<String, dynamic> toDriftMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'address': address,
      'phone': phone,
      'category': category,
      'icon': icon,
      'use_count': useCount,
      'is_synced': isSynced,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'address': address,
      'phone': phone,
      'category': category,
      'icon': icon,
      'use_count': useCount,
    };
  }

  /// Crear desde respuesta de Supabase
  factory EstablishmentModel.fromSupabase(Map<String, dynamic> json) {
    return EstablishmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      useCount: json['use_count'] as int? ?? 0,
      isSynced: true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
