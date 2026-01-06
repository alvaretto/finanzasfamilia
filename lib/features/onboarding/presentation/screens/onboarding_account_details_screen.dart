import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../models/account_template.dart';
import '../providers/onboarding_wizard_provider.dart';

/// Pantalla de configuración detallada de cuentas
/// Usa PageView para navegar entre las cuentas seleccionadas
class OnboardingAccountDetailsScreen extends ConsumerStatefulWidget {
  const OnboardingAccountDetailsScreen({super.key});

  @override
  ConsumerState<OnboardingAccountDetailsScreen> createState() =>
      _OnboardingAccountDetailsScreenState();
}

class _OnboardingAccountDetailsScreenState
    extends ConsumerState<OnboardingAccountDetailsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Controllers por tipo de cuenta
  final Map<AccountType, TextEditingController> _nameControllers = {};
  final Map<AccountType, TextEditingController> _balanceControllers = {};
  final Map<AccountType, TextEditingController> _limitControllers = {};
  final Map<AccountType, String?> _selectedSuggestions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Inicializar en el siguiente frame para asegurar que el provider esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final state = ref.read(onboardingWizardProvider);

    for (final type in state.selectedTypesList) {
      final template = AccountTemplate.getByType(type);
      if (template == null) continue;

      final existingData = state.getDataForType(type);

      _nameControllers[type] = TextEditingController(
        text: existingData?.name ?? template.defaultName,
      );

      _balanceControllers[type] = TextEditingController(
        text: existingData?.initialBalance.toStringAsFixed(0) ?? '0',
      );

      if (template.requiresCreditLimit) {
        _limitControllers[type] = TextEditingController(
          text: existingData?.creditLimit?.toStringAsFixed(0) ?? '0',
        );
      }

      if (template.suggestedNames != null) {
        _selectedSuggestions[type] = existingData?.bankName ??
            (existingData?.name != template.defaultName ? existingData?.name : null);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _balanceControllers.values) {
      controller.dispose();
    }
    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingWizardProvider);
    final selectedList = state.selectedTypesList;

    if (selectedList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/onboarding/accounts');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Cuentas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              context.go('/onboarding/accounts');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: 0.33 + (0.67 * (_currentPage + 1) / selectedList.length),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Indicador de página
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cuenta ${_currentPage + 1} de ${selectedList.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // Dots indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(selectedList.length, (index) {
                    return Container(
                      width: index == _currentPage ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // PageView con formularios
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: selectedList.length,
              itemBuilder: (context, index) {
                final type = selectedList[index];
                final template = AccountTemplate.getByType(type);

                if (template == null) return const SizedBox();

                return _buildAccountForm(type, template);
              },
            ),
          ),
        ],
      ),

      // Botones de navegación
      bottomNavigationBar: _buildBottomButtons(context, selectedList, state),
    );
  }

  Widget _buildAccountForm(AccountType type, AccountTemplate template) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = Color(int.parse(template.defaultColor.replaceFirst('#', '0xFF')));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con icono
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: selectedColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                template.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              template.defaultName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(
              template.description,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 32),

          // Selector de sugerencias (si aplica)
          if (template.suggestedNames != null) ...[
            Text(
              template.type == AccountType.wallet
                  ? '📱 ¿Cuál billetera?'
                  : '🏦 ¿Qué banco?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...template.suggestedNames!.map((suggestion) {
                  final isSelected = _selectedSuggestions[type] == suggestion;
                  return ChoiceChip(
                    label: Text(suggestion),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSuggestions[type] = suggestion;
                          _nameControllers[type]?.text = suggestion;
                        } else {
                          _selectedSuggestions[type] = null;
                          _nameControllers[type]?.text = template.defaultName;
                        }
                      });
                    },
                    selectedColor: selectedColor.withValues(alpha: 0.2),
                    checkmarkColor: selectedColor,
                  );
                }),
                // Opción "Otro"
                ChoiceChip(
                  label: const Text('Otro'),
                  selected: _selectedSuggestions[type] == 'otro',
                  onSelected: (selected) {
                    setState(() {
                      _selectedSuggestions[type] = selected ? 'otro' : null;
                      if (!selected) {
                        _nameControllers[type]?.text = template.defaultName;
                      }
                    });
                  },
                  selectedColor: selectedColor.withValues(alpha: 0.2),
                  checkmarkColor: selectedColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Campo: Nombre de la cuenta
          TextFormField(
            controller: _nameControllers[type],
            decoration: InputDecoration(
              labelText: '📝 Nombre de la cuenta',
              hintText: 'Ej: ${template.defaultName}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: _selectedSuggestions[type] == 'otro' || 
                     _selectedSuggestions[type] == null,
          ),

          const SizedBox(height: 16),

          // Campo: Saldo inicial / Deuda actual
          TextFormField(
            controller: _balanceControllers[type],
            decoration: InputDecoration(
              labelText: template.isAsset
                  ? '💵 Saldo actual (opcional)'
                  : '💳 Deuda actual (opcional)',
              hintText: '0',
              prefixText: '\$ ',
              suffixText: 'COP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
              helperText: template.isAsset
                  ? 'Puedes dejarlo en 0 y ajustarlo después'
                  : 'Cuánto debes actualmente',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),

          const SizedBox(height: 16),

          // Campo: Cupo (para tarjetas de crédito)
          if (template.requiresCreditLimit) ...[
            TextFormField(
              controller: _limitControllers[type],
              decoration: InputDecoration(
                labelText: '💳 Cupo total',
                hintText: '0',
                prefixText: '\$ ',
                suffixText: 'COP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.credit_card),
                helperText: 'Cupo máximo de la tarjeta',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Info adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Puedes editar esta información más tarde desde la sección de Cuentas',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    List<AccountType> selectedList,
    OnboardingWizardState state,
  ) {
    final isLastPage = _currentPage == selectedList.length - 1;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _saveCurrentAccountData(selectedList[_currentPage]);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('← Anterior'),
                ),
              ),

            if (_currentPage > 0) const SizedBox(width: 16),

            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: state.isLoading ? null : () => _handleNext(selectedList),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLastPage ? '✓ Finalizar' : 'Siguiente →',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCurrentAccountData(AccountType type) {
    final template = AccountTemplate.getByType(type);
    if (template == null) return;

    final name = _nameControllers[type]?.text ?? template.defaultName;
    final balance = double.tryParse(_balanceControllers[type]?.text ?? '0') ?? 0;
    final creditLimit = template.requiresCreditLimit
        ? double.tryParse(_limitControllers[type]?.text ?? '0')
        : null;
    final suggestion = _selectedSuggestions[type];
    final bankName = suggestion != null && suggestion != 'otro' ? suggestion : null;

    ref.read(onboardingWizardProvider.notifier).saveAccountData(
      type,
      AccountConfigData(
        type: type,
        name: name,
        initialBalance: balance,
        bankName: bankName,
        creditLimit: creditLimit,
        color: template.defaultColor,
        emoji: template.emoji,
      ),
    );
  }

  Future<void> _handleNext(List<AccountType> selectedList) async {
    _saveCurrentAccountData(selectedList[_currentPage]);

    if (_currentPage == selectedList.length - 1) {
      await _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final success = await ref.read(onboardingWizardProvider.notifier).complete();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Listo! Tus cuentas han sido creadas'),
          backgroundColor: AppColors.income,
        ),
      );
      context.go('/dashboard');
    } else {
      final error = ref.read(onboardingWizardProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${error ?? 'Error al crear cuentas'}'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }
}
