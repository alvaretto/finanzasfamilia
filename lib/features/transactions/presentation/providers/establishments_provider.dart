import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Hide Families to avoid conflict with Riverpod's Family class
import '../../../../core/database/app_database.dart' hide Families;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/establishment_model.dart';

part 'establishments_provider.g.dart';

/// Provider para acceder a la base de datos
final _databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Estado de los establecimientos
class EstablishmentsState {
  final List<EstablishmentModel> establishments;
  final bool isLoading;
  final String? error;

  const EstablishmentsState({
    this.establishments = const [],
    this.isLoading = false,
    this.error,
  });

  EstablishmentsState copyWith({
    List<EstablishmentModel>? establishments,
    bool? isLoading,
    String? error,
  }) {
    return EstablishmentsState(
      establishments: establishments ?? this.establishments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Establecimientos ordenados por uso (más usados primero)
  List<EstablishmentModel> get sortedByUsage {
    final sorted = List<EstablishmentModel>.from(establishments);
    sorted.sort((a, b) => b.useCount.compareTo(a.useCount));
    return sorted;
  }

  /// Buscar por nombre (para autocompletado)
  List<EstablishmentModel> search(String query) {
    if (query.isEmpty) return sortedByUsage;

    final lowerQuery = query.toLowerCase();
    return establishments.where((e) {
      return e.name.toLowerCase().contains(lowerQuery) ||
          (e.address?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Buscar establecimiento por ID
  EstablishmentModel? findById(String id) {
    try {
      return establishments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Notifier para manejar establecimientos
@riverpod
class Establishments extends _$Establishments {
  @override
  EstablishmentsState build() {
    _loadEstablishments();
    return const EstablishmentsState(isLoading: true);
  }

  Future<void> _loadEstablishments() async {
    try {
      final db = ref.read(_databaseProvider);
      final user = ref.read(currentUserProvider);

      if (user == null) {
        state = state.copyWith(
          establishments: [],
          isLoading: false,
        );
        return;
      }

      final rows = await (db.select(db.establishments)
            ..where((e) => e.userId.equals(user.id))
            ..orderBy([(e) => OrderingTerm.desc(e.useCount)]))
          .get();

      final models = rows
          .map((row) => EstablishmentModel(
                id: row.id,
                userId: row.userId,
                name: row.name,
                address: row.address,
                phone: row.phone,
                category: row.category,
                icon: row.icon,
                useCount: row.useCount,
                isSynced: row.isSynced,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
              ))
          .toList();

      state = state.copyWith(
        establishments: models,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar establecimientos: $e',
      );
    }
  }

  /// Recargar establecimientos
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadEstablishments();
  }

  /// Crear o buscar establecimiento por nombre
  /// Si existe, incrementa el contador de uso
  /// Si no existe, lo crea
  Future<EstablishmentModel> getOrCreate({
    required String name,
    String? address,
    String? phone,
    String? category,
  }) async {
    final db = ref.read(_databaseProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Buscar establecimiento existente por nombre exacto
    final existing = state.establishments.where(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
    );

    if (existing.isNotEmpty) {
      // Incrementar contador de uso
      final establishment = existing.first;
      await _incrementUseCount(establishment.id);
      return establishment;
    }

    // Crear nuevo establecimiento
    final newEstablishment = EstablishmentModel.create(
      userId: user.id,
      name: name,
      address: address,
      phone: phone,
      category: category,
    );

    await db.into(db.establishments).insert(EstablishmentsCompanion.insert(
          id: newEstablishment.id,
          userId: newEstablishment.userId,
          name: newEstablishment.name,
          address: Value(newEstablishment.address),
          phone: Value(newEstablishment.phone),
          category: Value(newEstablishment.category),
          icon: Value(newEstablishment.icon),
          useCount: Value(newEstablishment.useCount),
          isSynced: Value(newEstablishment.isSynced),
        ));

    await _loadEstablishments();
    return newEstablishment;
  }

  /// Incrementar contador de uso
  Future<void> _incrementUseCount(String id) async {
    try {
      final db = ref.read(_databaseProvider);
      final establishment = state.findById(id);
      if (establishment == null) return;

      await (db.update(db.establishments)..where((e) => e.id.equals(id)))
          .write(EstablishmentsCompanion(
        useCount: Value(establishment.useCount + 1),
        updatedAt: Value(DateTime.now()),
      ));

      // Actualizar estado local
      state = state.copyWith(
        establishments: state.establishments.map((e) {
          if (e.id == id) {
            return e.copyWith(useCount: e.useCount + 1);
          }
          return e;
        }).toList(),
      );
    } catch (e) {
      // Ignorar errores de incremento
    }
  }

  /// Actualizar establecimiento
  Future<void> update(EstablishmentModel establishment) async {
    try {
      final db = ref.read(_databaseProvider);

      await (db.update(db.establishments)
            ..where((e) => e.id.equals(establishment.id)))
          .write(EstablishmentsCompanion(
        name: Value(establishment.name),
        address: Value(establishment.address),
        phone: Value(establishment.phone),
        category: Value(establishment.category),
        icon: Value(establishment.icon),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      await _loadEstablishments();
    } catch (e) {
      state = state.copyWith(
        error: 'Error al actualizar establecimiento: $e',
      );
    }
  }

  /// Eliminar establecimiento
  Future<void> delete(String id) async {
    try {
      final db = ref.read(_databaseProvider);

      await (db.delete(db.establishments)..where((e) => e.id.equals(id))).go();

      state = state.copyWith(
        establishments: state.establishments.where((e) => e.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al eliminar establecimiento: $e',
      );
    }
  }
}

/// Provider simple para lista de establecimientos (para selects)
@riverpod
List<EstablishmentModel> establishmentsList(Ref ref) {
  final state = ref.watch(establishmentsProvider);
  return state.sortedByUsage;
}
