import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/places_table.dart';

part 'places_dao.g.dart';

/// DAO para operaciones con lugares
@DriftAccessor(tables: [Places])
class PlacesDao extends DatabaseAccessor<AppDatabase> with _$PlacesDaoMixin {
  PlacesDao(super.db);

  /// Obtiene todos los lugares activos ordenados por uso
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PlaceEntry>> getAllActivePlaces() {
    return (select(places)
          ..where((p) => p.isActive.equals(true) | p.isActive.isNull())
          ..orderBy([
            (p) => OrderingTerm.desc(p.usageCount),
            (p) => OrderingTerm.asc(p.name),
          ]))
        .get();
  }

  /// Obtiene todos los lugares
  Future<List<PlaceEntry>> getAllPlaces() {
    return (select(places)
          ..orderBy([
            (p) => OrderingTerm.desc(p.usageCount),
            (p) => OrderingTerm.asc(p.name),
          ]))
        .get();
  }

  /// Obtiene lugares por tipo
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PlaceEntry>> getPlacesByType(PlaceType type) {
    return (select(places)
          ..where((p) => p.type.equals(type.name))
          ..where((p) => p.isActive.equals(true) | p.isActive.isNull())
          ..orderBy([
            (p) => OrderingTerm.desc(p.usageCount),
            (p) => OrderingTerm.asc(p.name),
          ]))
        .get();
  }

  /// Busca lugares por nombre
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PlaceEntry>> searchByName(String query) {
    return (select(places)
          ..where((p) => p.name.like('%$query%'))
          ..where((p) => p.isActive.equals(true) | p.isActive.isNull())
          ..orderBy([(p) => OrderingTerm.desc(p.usageCount)]))
        .get();
  }

  /// Obtiene un lugar por ID
  Future<PlaceEntry?> getPlaceById(String id) {
    return (select(places)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Inserta un nuevo lugar
  Future<void> insertPlace(PlacesCompanion place) {
    return into(places).insert(place);
  }

  /// Inserta múltiples lugares
  Future<void> insertPlaces(List<PlacesCompanion> placesList) {
    return batch((batch) {
      batch.insertAll(places, placesList);
    });
  }

  /// Actualiza un lugar
  Future<bool> updatePlace(PlaceEntry place) {
    return update(places).replace(place);
  }

  /// Incrementa el contador de uso
  Future<void> incrementUsageCount(String id) async {
    final place = await getPlaceById(id);
    if (place != null) {
      await (update(places)..where((p) => p.id.equals(id))).write(
        PlacesCompanion(
          usageCount: Value((place.usageCount ?? 0) + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Elimina un lugar (soft delete)
  Future<int> deactivatePlace(String id) {
    return (update(places)..where((p) => p.id.equals(id)))
        .write(const PlacesCompanion(isActive: Value(false)));
  }

  /// Obtiene lugares más usados
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PlaceEntry>> getMostUsedPlaces({int limit = 10}) {
    return (select(places)
          ..where((p) => p.isActive.equals(true) | p.isActive.isNull())
          ..orderBy([(p) => OrderingTerm.desc(p.usageCount)])
          ..limit(limit))
        .get();
  }
}
