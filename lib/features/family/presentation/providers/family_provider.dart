import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/family_repository.dart';
import '../../domain/models/family_model.dart';

/// Provider del repositorio
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

/// Estado de familias
class FamilyState {
  final List<FamilyModel> families;
  final FamilyModel? selectedFamily;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const FamilyState({
    this.families = const [],
    this.selectedFamily,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  FamilyState copyWith({
    List<FamilyModel>? families,
    FamilyModel? selectedFamily,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FamilyState(
      families: families ?? this.families,
      selectedFamily: clearSelected ? null : (selectedFamily ?? this.selectedFamily),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier de familias
class FamilyNotifier extends StateNotifier<FamilyState> {
  final FamilyRepository _repository;
  final String? _userId;
  StreamSubscription? _subscription;

  FamilyNotifier(this._repository, this._userId) : super(const FamilyState()) {
    if (_userId != null) {
      _loadFamilies();
      _startWatching();
    }
  }

  void _startWatching() {
    final userId = _userId;
    if (userId == null) return;

    _subscription = _repository.watchFamilies(userId).listen(
      (families) {
        state = state.copyWith(families: families, clearError: true);
      },
      onError: (e) {
        state = state.copyWith(errorMessage: 'Error al observar familias: $e');
      },
    );
  }

  Future<void> _loadFamilies() async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final families = await _repository.getFamilies(userId);
      state = state.copyWith(families: families, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar familias: $e',
      );
    }
  }

  /// Crear familia
  Future<bool> createFamily(String name) async {
    final userId = _userId;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final family = await _repository.createFamily(name, userId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Familia "$name" creada exitosamente',
        selectedFamily: family,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear familia: $e',
      );
      return false;
    }
  }

  /// Unirse a familia
  Future<bool> joinFamily(String inviteCode) async {
    final userId = _userId;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final family = await _repository.joinFamily(inviteCode, userId);
      if (family == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Código de invitación inválido',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Te has unido a "${family.name}"',
        selectedFamily: family,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al unirse a familia: $e',
      );
      return false;
    }
  }

  /// Actualizar nombre
  Future<bool> updateFamilyName(String familyId, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateFamilyName(familyId, name);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Nombre actualizado',
      );
      await _loadFamilies();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar: $e',
      );
      return false;
    }
  }

  /// Cambiar rol de miembro
  Future<bool> updateMemberRole(String memberId, FamilyRole role) async {
    try {
      await _repository.updateMemberRole(memberId, role);
      await _loadFamilies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al cambiar rol: $e');
      return false;
    }
  }

  /// Eliminar miembro
  Future<bool> removeMember(String memberId) async {
    try {
      await _repository.removeMember(memberId);
      state = state.copyWith(successMessage: 'Miembro eliminado');
      await _loadFamilies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar miembro: $e');
      return false;
    }
  }

  /// Salir de familia
  Future<bool> leaveFamily(String familyId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _repository.leaveFamily(familyId, userId);
      state = state.copyWith(
        successMessage: 'Has salido de la familia',
        clearSelected: true,
      );
      await _loadFamilies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al salir: $e');
      return false;
    }
  }

  /// Eliminar familia
  Future<bool> deleteFamily(String familyId) async {
    try {
      await _repository.deleteFamily(familyId);
      state = state.copyWith(
        successMessage: 'Familia eliminada',
        clearSelected: true,
      );
      await _loadFamilies();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar: $e');
      return false;
    }
  }

  /// Seleccionar familia
  void selectFamily(FamilyModel? family) {
    state = state.copyWith(
      selectedFamily: family,
      clearSelected: family == null,
    );
  }

  /// Limpiar mensajes
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Refrescar
  Future<void> refresh() => _loadFamilies();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider principal
final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  final authState = ref.watch(authProvider);
  return FamilyNotifier(repository, authState.user?.id);
});

/// Provider de lista de familias
final familiesListProvider = Provider<List<FamilyModel>>((ref) {
  return ref.watch(familyProvider).families;
});

/// Provider de familia seleccionada
final selectedFamilyProvider = Provider<FamilyModel?>((ref) {
  return ref.watch(familyProvider).selectedFamily;
});
