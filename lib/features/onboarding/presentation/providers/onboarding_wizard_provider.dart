import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/account_template.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Clave para SharedPreferences - indica si el onboarding fue completado
const String _onboardingCompletedKey = 'onboarding_accounts_completed';

/// Provider para verificar si el onboarding fue completado
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompletedKey) ?? false;
});

/// Estado del wizard de onboarding
class OnboardingWizardState {
  final int currentStep;
  final Set<AccountType> selectedTypes;
  final Map<AccountType, AccountConfigData> accountsData;
  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingWizardState({
    this.currentStep = 0,
    this.selectedTypes = const {},
    this.accountsData = const {},
    this.isCompleted = false,
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingWizardState copyWith({
    int? currentStep,
    Set<AccountType>? selectedTypes,
    Map<AccountType, AccountConfigData>? accountsData,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      accountsData: accountsData ?? this.accountsData,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Lista ordenada de tipos seleccionados
  List<AccountType> get selectedTypesList => selectedTypes.toList();

  /// Cantidad de cuentas seleccionadas
  int get selectedCount => selectedTypes.length;

  /// Verifica si un tipo está seleccionado
  bool isTypeSelected(AccountType type) => selectedTypes.contains(type);

  /// Obtiene los datos de configuración para un tipo
  AccountConfigData? getDataForType(AccountType type) => accountsData[type];
}

/// Notifier del wizard de onboarding
class OnboardingWizardNotifier extends StateNotifier<OnboardingWizardState> {
  final Ref _ref;

  OnboardingWizardNotifier(this._ref) : super(const OnboardingWizardState());

  /// Selecciona o deselecciona un tipo de cuenta
  void toggleAccountType(AccountType type) {
    final selected = {...state.selectedTypes};
    final data = {...state.accountsData};

    if (selected.contains(type)) {
      selected.remove(type);
      data.remove(type);
    } else {
      selected.add(type);
      // Inicializar datos del template
      final template = AccountTemplate.getByType(type);
      if (template != null) {
        data[type] = AccountConfigData.fromTemplate(template);
      }
    }

    state = state.copyWith(
      selectedTypes: selected,
      accountsData: data,
    );
  }

  /// Guarda la configuración de una cuenta
  void saveAccountData(AccountType type, AccountConfigData data) {
    final accountsData = {...state.accountsData};
    accountsData[type] = data;
    state = state.copyWith(accountsData: accountsData);
  }

  /// Actualiza un campo específico de la configuración
  void updateAccountField(AccountType type, {
    String? name,
    double? initialBalance,
    String? bankName,
    double? creditLimit,
  }) {
    final currentData = state.accountsData[type];
    if (currentData == null) return;

    final updatedData = currentData.copyWith(
      name: name,
      initialBalance: initialBalance,
      bankName: bankName,
      creditLimit: creditLimit,
    );

    saveAccountData(type, updatedData);
  }

  /// Avanza al siguiente paso
  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Retrocede al paso anterior
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Va a un paso específico
  void goToStep(int step) {
    if (step >= 0 && step <= state.selectedTypes.length) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Crea la cuenta de efectivo predefinida (sistema)
  Future<bool> createDefaultCashAccount() async {
    final accountsNotifier = _ref.read(accountsProvider.notifier);
    
    try {
      final success = await accountsNotifier.createAccount(
        name: '💵 Efectivo',
        type: AccountType.cash,
        balance: 0,
        color: '#4CAF50',
        icon: 'payments',
        // isSystem: true - Esto se manejará cuando agreguemos el campo
      );
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al crear cuenta de efectivo: $e');
      return false;
    }
  }

  /// Crea todas las cuentas configuradas
  Future<bool> createAccounts() async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final accountsNotifier = _ref.read(accountsProvider.notifier);

      // Crear las cuentas seleccionadas
      for (final entry in state.accountsData.entries) {
        final type = entry.key;
        final data = entry.value;

        final success = await accountsNotifier.createAccount(
          name: data.name,
          type: type,
          balance: data.initialBalance,
          bankName: data.bankName,
          creditLimit: data.creditLimit ?? 0,
          icon: type.icon,
          color: data.color,
        );

        if (!success) {
          // Si falló una cuenta, continuar con las demás
          // El error específico se manejará en el provider de cuentas
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear cuentas: $e',
      );
      return false;
    }
  }

  /// Completa el onboarding
  Future<bool> complete() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Crear todas las cuentas configuradas
      final success = await createAccounts();

      if (success) {
        // Marcar onboarding como completado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingCompletedKey, true);

        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
        );
        
        // Invalidar el provider de estado del onboarding
        _ref.invalidate(onboardingCompletedProvider);
        
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al completar onboarding: $e',
      );
      return false;
    }
  }

  /// Omitir onboarding (solo usar efectivo predefinido)
  Future<bool> skip() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Marcar onboarding como completado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);

      state = state.copyWith(
        isLoading: false,
        isCompleted: true,
      );
      
      // Invalidar el provider de estado del onboarding
      _ref.invalidate(onboardingCompletedProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al omitir onboarding: $e',
      );
      return false;
    }
  }

  /// Reinicia el wizard (para testing o rehacer)
  void reset() {
    state = const OnboardingWizardState();
  }

  /// Limpia el mensaje de error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider principal del wizard de onboarding
final onboardingWizardProvider =
    StateNotifierProvider.autoDispose<OnboardingWizardNotifier, OnboardingWizardState>(
  (ref) => OnboardingWizardNotifier(ref),
);

/// Provider para verificar si hay cuentas seleccionadas
final hasSelectedAccountsProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(onboardingWizardProvider).selectedTypes.isNotEmpty;
});

/// Provider para obtener la cantidad de cuentas seleccionadas
final selectedAccountsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(onboardingWizardProvider).selectedCount;
});
