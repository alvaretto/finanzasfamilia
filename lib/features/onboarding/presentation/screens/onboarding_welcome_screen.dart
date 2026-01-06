import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_wizard_provider.dart';

/// Pantalla de bienvenida del wizard de onboarding
/// Muestra introducción y características de la app
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Logo animado
              _buildLogo(context).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              ).fadeIn(),

              const SizedBox(height: 32),

              // Título
              Text(
                '¡Bienvenido a\nFinanzas Familiares! 🎉',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

              const SizedBox(height: 16),

              // Descripción
              Text(
                'Vamos a configurar tus cuentas para que puedas empezar a llevar el control de tu dinero de manera fácil y clara.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 48),

              // Características
              _buildFeatureItem(
                context,
                icon: Icons.account_balance,
                title: 'Cuentas Bancarias',
                description: 'Lleva el control de todos tus bancos',
                delay: 500,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                icon: Icons.smartphone,
                title: 'Billeteras Digitales',
                description: 'Nequi, DaviPlata y más',
                delay: 600,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                icon: Icons.savings,
                title: 'Ahorros e Inversiones',
                description: 'Tu dinero guardado o invertido',
                delay: 700,
              ),

              const Spacer(),

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
                    Icon(Icons.info_outline, color: AppColors.income),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💵 Ya tienes una cuenta de "Efectivo" creada automáticamente',
                        style: TextStyle(
                          color: AppColors.income,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 24),

              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/onboarding/accounts'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Comenzar →',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              // Botón omitir
              TextButton(
                onPressed: () => _showSkipDialog(context, ref),
                child: Text(
                  'Omitir por ahora',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_balance_wallet,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.2, end: 0);
  }

  Future<void> _showSkipDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.skip_next, color: AppColors.warning),
            SizedBox(width: 12),
            Text('¿Omitir configuración?'),
          ],
        ),
        content: const Text(
          'Podrás agregar tus cuentas más tarde desde el menú de Cuentas.\n\n'
          'Solo se usará la cuenta de "💵 Efectivo" por defecto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Omitir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(onboardingWizardProvider.notifier).skip();
      if (success && context.mounted) {
        context.go('/dashboard');
      }
    }
  }
}
