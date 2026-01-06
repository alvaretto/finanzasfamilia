import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../models/account_template.dart';
import '../providers/onboarding_wizard_provider.dart';
import '../widgets/account_selection_card.dart';

/// Pantalla de selección de cuentas en el wizard de onboarding
/// Permite seleccionar qué tipos de cuenta configurar
class OnboardingAccountsScreen extends ConsumerWidget {
  const OnboardingAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingWizardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Cuentas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/welcome'),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: 0.33,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Título
                Text(
                  '¿Dónde guardas tu dinero? 💰',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Selecciona todas las cuentas que uses. No te preocupes, podrás agregar más después.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // Nota sobre efectivo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.income),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '💵 "Efectivo" ya está listo (se crea automáticamente)',
                          style: TextStyle(
                            color: AppColors.income,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sección: Lo que Tengo (Activos)
                _buildSectionHeader(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: '💰 Lo que Tengo',
                  subtitle: 'Dinero disponible',
                  color: AppColors.income,
                ),

                const SizedBox(height: 12),

                ...AccountTemplate.assets.map((template) {
                  final isSelected = state.isTypeSelected(template.type);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccountSelectionCard(
                      template: template,
                      isSelected: isSelected,
                      onTap: () => ref
                          .read(onboardingWizardProvider.notifier)
                          .toggleAccountType(template.type),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Sección: Lo que Debo (Pasivos) - Expandible
                _buildLiabilitiesSection(context, ref, state),

                // Espacio para botones flotantes
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Botones flotantes
      bottomNavigationBar: _buildBottomButtons(context, ref, state),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiabilitiesSection(
    BuildContext context,
    WidgetRef ref,
    OnboardingWizardState state,
  ) {
    final liabilityTemplates = AccountTemplate.liabilities;
    final hasSelectedLiabilities = liabilityTemplates.any(
      (t) => state.isTypeSelected(t.type),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: hasSelectedLiabilities,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.credit_card, color: AppColors.expense, size: 20),
        ),
        title: const Text(
          '💳 Lo que Debo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Tarjetas de crédito, préstamos (opcional)'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: liabilityTemplates.map((template) {
                final isSelected = state.isTypeSelected(template.type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccountSelectionCard(
                    template: template,
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(onboardingWizardProvider.notifier)
                        .toggleAccountType(template.type),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    WidgetRef ref,
    OnboardingWizardState state,
  ) {
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
            // Botón omitir
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final success = await ref.read(onboardingWizardProvider.notifier).skip();
                  if (success && context.mounted) {
                    context.go('/dashboard');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Omitir'),
              ),
            ),

            const SizedBox(width: 16),

            // Botón continuar
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: state.selectedTypes.isEmpty
                    ? null
                    : () => context.go('/onboarding/details'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuar',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (state.selectedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.selectedCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
