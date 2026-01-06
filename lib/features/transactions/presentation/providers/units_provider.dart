import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Hide Families to avoid conflict with Riverpod's Family class
import '../../../../core/database/app_database.dart' hide Families;
import '../../domain/models/unit_model.dart';

part 'units_provider.g.dart';

/// Provider para acceder a la base de datos
final _databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Estado de las unidades de medida
class UnitsState {
  final List<UnitModel> units;
  final bool isLoading;
  final String? error;

  const UnitsState({
    this.units = const [],
    this.isLoading = false,
    this.error,
  });

  UnitsState copyWith({
    List<UnitModel>? units,
    bool? isLoading,
    String? error,
  }) {
    return UnitsState(
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Unidades filtradas por categoría
  List<UnitModel> byCategory(String category) {
    return units.where((u) => u.category == category).toList();
  }

  /// Unidades de peso
  List<UnitModel> get weightUnits => byCategory('weight');

  /// Unidades de volumen
  List<UnitModel> get volumeUnits => byCategory('volume');

  /// Unidades de longitud
  List<UnitModel> get lengthUnits => byCategory('length');

  /// Unidades discretas
  List<UnitModel> get discreteUnits => byCategory('unit');

  /// Buscar unidad por ID
  UnitModel? findById(String id) {
    try {
      return units.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Notifier para manejar unidades de medida
@riverpod
class Units extends _$Units {
  @override
  UnitsState build() {
    _loadUnits();
    return const UnitsState(isLoading: true);
  }

  Future<void> _loadUnits() async {
    try {
      final db = ref.read(_databaseProvider);
      final rows = await db.select(db.units).get();

      final unitModels = rows.map((row) => UnitModel(
            id: row.id,
            name: row.name,
            shortName: row.shortName,
            category: row.category,
            isSystem: row.isSystem,
            createdAt: row.createdAt,
          )).toList();

      // Ordenar por nombre
      unitModels.sort((a, b) => a.name.compareTo(b.name));

      state = state.copyWith(
        units: unitModels,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar unidades: $e',
      );
    }
  }

  /// Recargar unidades
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadUnits();
  }

  /// Agregar unidad personalizada
  Future<void> addCustomUnit({
    required String name,
    required String shortName,
    required String category,
  }) async {
    try {
      final db = ref.read(_databaseProvider);
      final id = 'unit_custom_${DateTime.now().millisecondsSinceEpoch}';

      await db.into(db.units).insert(UnitsCompanion.insert(
            id: id,
            name: name,
            shortName: shortName,
            category: category,
            isSystem: const Value(false),
          ));

      await _loadUnits();
    } catch (e) {
      state = state.copyWith(
        error: 'Error al agregar unidad: $e',
      );
    }
  }
}

/// Provider simple para lista de unidades (para selects)
@riverpod
List<UnitModel> unitsList(Ref ref) {
  final unitsState = ref.watch(unitsProvider);
  return unitsState.units;
}

/// Provider para unidades agrupadas por categoría
@riverpod
Map<String, List<UnitModel>> unitsGrouped(Ref ref) {
  final units = ref.watch(unitsListProvider);
  final grouped = <String, List<UnitModel>>{};

  for (final unit in units) {
    grouped.putIfAbsent(unit.category, () => []).add(unit);
  }

  return grouped;
}
