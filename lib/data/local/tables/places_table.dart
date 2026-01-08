import 'package:drift/drift.dart';

/// Tipos de lugares de compra/venta
enum PlaceType {
  /// Supermercado (Éxito, Jumbo, D1, etc.)
  supermarket,

  /// Tienda de barrio
  store,

  /// Venta callejera
  street,

  /// Compra web/online
  web,

  /// Restaurante
  restaurant,

  /// Farmacia
  pharmacy,

  /// Estación de servicio
  gasStation,

  /// Centro comercial
  mall,

  /// Otro
  other,
}

/// Tabla de Lugares
/// Registra dónde se realizan las compras/ventas
@DataClassName('PlaceEntry')
class Places extends Table {
  /// ID único (UUID)
  TextColumn get id => text()();

  /// Nombre del lugar (Éxito Poblado, Tienda Don José, etc.)
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Tipo de lugar
  TextColumn get type => text()();

  /// Dirección (opcional)
  TextColumn get address => text().nullable()();

  /// Ciudad (opcional)
  TextColumn get city => text().nullable()();

  /// Latitud (para geolocalización futura)
  RealColumn get latitude => real().nullable()();

  /// Longitud (para geolocalización futura)
  RealColumn get longitude => real().nullable()();

  /// Notas adicionales
  TextColumn get notes => text().nullable()();

  /// Si está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Si es del sistema (no editable por usuario)
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// Contador de uso (para ordenar por frecuencia)
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
