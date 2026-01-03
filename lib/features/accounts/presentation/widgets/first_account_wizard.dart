import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_provider.dart';

/// Templates de cuentas comunes para creacion rapida
class AccountTemplate {
  final String name;
  final String description;
  final AccountType type;
  final IconData icon;
  final Color color;
  final String colorHex;

  const AccountTemplate({
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.colorHex,
  });
}

const _accountTemplates = [
  AccountTemplate(
    name: 'Efectivo',
    description: 'Dinero en tu cartera',
    type: AccountType.cash,
    icon: Icons.payments,
    color: Color(0xFF4CAF50),
    colorHex: '#4CAF50',
  ),
  AccountTemplate(
    name: 'Cuenta Bancaria',
    description: 'Tu cuenta de debito principal',
    type: AccountType.bank,
    icon: Icons.account_balance,
    color: Color(0xFF2196F3),
    colorHex: '#2196F3',
  ),
  AccountTemplate(
    name: 'Tarjeta de Credito',
    description: 'Para controlar tus deudas',
    type: AccountType.credit,
    icon: Icons.credit_card,
    color: Color(0xFFF44336),
    colorHex: '#F44336',
  ),
  AccountTemplate(
    name: 'Ahorros',
    description: 'Fondo de emergencia o metas',
    type: AccountType.savings,
    icon: Icons.savings,
    color: Color(0xFF9C27B0),
    colorHex: '#9C27B0',
  ),
  AccountTemplate(
    name: 'Billetera Digital',
    description: 'Nequi, Daviplata, PayPal...',
    type: AccountType.wallet,
    icon: Icons.account_balance_wallet,
    color: Color(0xFF00BCD4),
    colorHex: '#00BCD4',
  ),
];

/// Wizard para crear la primera cuenta
class FirstAccountWizard extends ConsumerStatefulWidget {
  const FirstAccountWizard({super.key});

  @override
  ConsumerState<FirstAccountWizard> createState() => _FirstAccountWizardState();
}

class _FirstAccountWizardState extends ConsumerState<FirstAccountWizard> {
  int _currentStep = 0;
  AccountTemplate? _selectedTemplate;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header con icono y bienvenida
        _buildHeader(context),
        const SizedBox(height: AppSpacing.xl),

        // Contenido segun el paso
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 0
                ? _buildTemplateSelection(context)
                : _buildAccountForm(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentStep == 0 ? Icons.rocket_launch : Icons.edit_note,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _currentStep == 0
                ? 'Comienza tu viaje financiero'
                : 'Configura tu cuenta',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _currentStep == 0
                ? 'Selecciona el tipo de cuenta que quieres crear primero'
                : 'Personaliza los detalles de tu ${_selectedTemplate?.name ?? "cuenta"}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Templates comunes
          ..._accountTemplates.map((template) => _buildTemplateCard(
                context,
                template: template,
              )),
          const SizedBox(height: AppSpacing.md),
          // Opcion personalizada
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTemplate = const AccountTemplate(
                  name: 'Cuenta personalizada',
                  description: 'Crea una cuenta a tu medida',
                  type: AccountType.bank,
                  icon: Icons.tune,
                  color: Color(0xFF607D8B),
                  colorHex: '#607D8B',
                );
                _nameController.text = '';
                _currentStep = 1;
              });
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Crear cuenta personalizada'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required AccountTemplate template,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTemplate = template;
            _nameController.text = template.name;
            _currentStep = 1;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  template.icon,
                  color: template.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountForm(BuildContext context) {
    final template = _selectedTemplate!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono del tipo seleccionado
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  template.icon,
                  color: template.color,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nombre de la cuenta
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre de la cuenta',
                hintText: 'ej. ${template.name}',
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un nombre para tu cuenta';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Balance inicial
            TextFormField(
              controller: _balanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: template.type == AccountType.credit
                    ? 'Deuda actual'
                    : 'Balance actual',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                helperText: template.type == AccountType.credit
                    ? 'Cuanto debes actualmente en esta tarjeta'
                    : 'Cuanto dinero tienes en esta cuenta hoy',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el balance actual';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Boton crear
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createAccount,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Creando...' : 'Crear cuenta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Boton volver
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _currentStep = 0;
                        _selectedTemplate = null;
                      });
                    },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Elegir otro tipo'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final template = _selectedTemplate!;
      final balance = double.tryParse(_balanceController.text) ?? 0.0;

      final success = await ref.read(accountsProvider.notifier).createAccount(
            name: _nameController.text.trim(),
            type: template.type,
            currency: 'MXN',
            balance: template.type == AccountType.credit ? -balance : balance,
            color: template.colorHex,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('${_nameController.text} creada exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
