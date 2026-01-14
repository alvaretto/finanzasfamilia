import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../application/providers/accounting_provider.dart';
import '../../application/providers/database_provider.dart';
import '../../application/providers/categories_provider.dart';
import '../../data/local/database.dart';

/// Lista de iconos disponibles para cuentas
const _accountIcons = [
  '💰', '💵', '💳', '🏦', '📱', '💎', '🪙', '💸', '🏧', '💹',
  '🐷', '🎯', '🏠', '🚗', '📈', '💼', '🎁', '🛡️', '⭐', '🔒',
];

/// Lista de colores disponibles
const _accountColors = [
  '#4CAF50', // Verde
  '#2196F3', // Azul
  '#9C27B0', // Púrpura
  '#F44336', // Rojo
  '#FF9800', // Naranja
  '#00BCD4', // Cyan
  '#E91E63', // Rosa
  '#673AB7', // Deep Purple
  '#009688', // Teal
  '#795548', // Brown
];

/// Provider para el icono seleccionado de cuenta
final accountIconProvider = StateProvider<String>((ref) => '💰');

/// Provider para el color seleccionado
final accountColorProvider = StateProvider<String>((ref) => '#4CAF50');

/// Provider para la categoría de cuenta seleccionada
final accountCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Provider para incluir en total
final includeInTotalProvider = StateProvider<bool>((ref) => true);

/// Pantalla de formulario para crear/editar cuentas
class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountDisplayDto? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0', 'es_CO');
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _initializeForEdit();
    } else {
      _balanceController.text = '0';
    }
  }

  void _initializeForEdit() {
    final account = widget.account!;
    _nameController.text = account.name;
    _balanceController.text = _numberFormat.format(account.balance);
    _descriptionController.text = account.description ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountIconProvider.notifier).state = account.icon ?? '💰';
      ref.read(accountColorProvider.notifier).state = account.color ?? '#4CAF50';
      ref.read(accountCategoryIdProvider.notifier).state = account.categoryId;
      ref.read(includeInTotalProvider.notifier).state = account.includeInTotal;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIcon = ref.watch(accountIconProvider);
    final selectedColor = ref.watch(accountColorProvider);
    final includeInTotal = ref.watch(includeInTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
        actions: [
          // Solo mostrar botón eliminar si NO es cuenta del sistema
          if (isEditing && !(widget.account?.isSystem ?? false))
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmDelete,
                    tooltip: 'Eliminar cuenta',
                  ),
          // Mostrar indicador si es cuenta del sistema
          if (isEditing && (widget.account?.isSystem ?? false))
            Tooltip(
              message: 'Cuenta predefinida (no eliminable)',
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview de la cuenta
            _buildPreviewCard(selectedIcon, selectedColor),
            const SizedBox(height: 24),

            // Campo de nombre
            _buildNameField(),
            const SizedBox(height: 16),

            // Campo de saldo inicial
            _buildBalanceField(selectedColor),
            const SizedBox(height: 16),

            // Selector de categoría (tipo de cuenta)
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // Selector de icono
            _buildIconSelector(selectedIcon),
            const SizedBox(height: 16),

            // Selector de color
            _buildColorSelector(selectedColor),
            const SizedBox(height: 16),

            // Campo de descripción
            _buildDescriptionField(),
            const SizedBox(height: 16),

            // Switch incluir en total
            _buildIncludeInTotalSwitch(includeInTotal),
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveAccount,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving
                  ? 'Guardando...'
                  : (isEditing ? 'Actualizar' : 'Crear')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(String icon, String colorHex) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final name = _nameController.text.isEmpty
        ? 'Nombre de cuenta'
        : _nameController.text;
    final balance = _balanceController.text.isEmpty
        ? '0'
        : _balanceController.text;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$ $balance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        prefixIcon: Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(),
        hintText: 'Ej: Nequi, Efectivo, Ahorros...',
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa un nombre';
        }
        if (value.trim().length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        if (value.trim().length > 50) {
          return 'El nombre es muy largo';
        }
        return null;
      },
    );
  }

  Widget _buildBalanceField(String colorHex) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return TextFormField(
      controller: _balanceController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorFormatter(),
      ],
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      decoration: InputDecoration(
        labelText: isEditing ? 'Saldo actual' : 'Saldo inicial',
        prefixText: '\$ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        border: const OutlineInputBorder(),
        filled: true,
        helperText: isEditing
            ? 'Este saldo se actualizará con las transacciones'
            : 'Ingresa el saldo inicial de la cuenta',
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa un saldo';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    final selectedCategoryId = ref.watch(accountCategoryIdProvider);
    // Obtener categorías de tipo asset (activos)
    final categoriesAsync = ref.watch(categoriesByTypeProvider('asset'));

    return categoriesAsync.when(
      data: (categories) {
        final rootCategories =
            categories.where((c) => c.parentId == null).toList();

        // Eliminar duplicados por ID
        final uniqueCategories = <String, CategoryEntry>{};
        for (final category in rootCategories) {
          uniqueCategories[category.id] = category;
        }
        final items = uniqueCategories.values.toList();

        // Verificar que el valor seleccionado existe en los items
        final effectiveValue = (selectedCategoryId != null &&
                selectedCategoryId.isNotEmpty &&
                items.any((c) => c.id == selectedCategoryId))
            ? selectedCategoryId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          decoration: const InputDecoration(
            labelText: 'Tipo de cuenta',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: items.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Row(
                children: [
                  Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            ref.read(accountCategoryIdProvider.notifier).state = value;
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona un tipo de cuenta';
            }
            return null;
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error cargando tipos de cuenta'),
    );
  }

  Widget _buildIconSelector(String selectedIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icono',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _accountIcons.map((icon) {
              final isSelected = icon == selectedIcon;
              return InkWell(
                onTap: () {
                  ref.read(accountIconProvider.notifier).state = icon;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(String selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _accountColors.map((colorHex) {
              final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
              final isSelected = colorHex == selectedColor;
              return InkWell(
                onTap: () {
                  ref.read(accountColorProvider.notifier).state = colorHex;
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(),
        hintText: 'Ej: Cuenta de ahorros para emergencias',
      ),
    );
  }

  Widget _buildIncludeInTotalSwitch(bool includeInTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Row(
            children: [
              const Text('Incluir en balance total'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showBalanceHelpDialog(),
                child: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            includeInTotal
                ? 'Esta cuenta SÍ suma al balance general'
                : 'Esta cuenta NO suma al balance general',
            style: TextStyle(
              color: includeInTotal ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          value: includeInTotal,
          onChanged: (value) {
            ref.read(includeInTotalProvider.notifier).state = value;
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ],
    );
  }

  void _showBalanceHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('¿Qué es el Balance Total?')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El balance total representa cuánto dinero real y disponible tienes.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                '✅ INCLUIR en balance:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 4),
              Text('• Efectivo en billetera'),
              Text('• Cuentas bancarias (Nequi, Bancolombia, etc.)'),
              Text('• Ahorros disponibles'),
              Text('• Tarjetas de crédito (restan como deuda)'),
              SizedBox(height: 16),
              Text(
                '❌ NO INCLUIR en balance:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              SizedBox(height: 4),
              Text('• Puntos de fidelidad (Puntos Colombia, Éxito)'),
              Text('• Millas de viajero frecuente'),
              Text('• CDTs bloqueados (hasta vencimiento)'),
              Text('• Cuentas de terceros que administras'),
              SizedBox(height: 16),
              Text(
                '💡 Consejo:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              SizedBox(height: 4),
              Text(
                'Pregúntate: "¿Puedo usar este dinero hoy para pagar el mercado?" '
                'Si la respuesta es NO, probablemente no debería sumar al balance.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final selectedIcon = ref.read(accountIconProvider);
    final selectedColor = ref.read(accountColorProvider);
    final categoryId = ref.read(accountCategoryIdProvider);
    final includeInTotal = ref.read(includeInTotalProvider);

    final name = _nameController.text.trim();
    final balance = double.parse(_balanceController.text.replaceAll('.', ''));
    final description = _descriptionController.text.trim();

    final db = ref.read(appDatabaseProvider);

    try {
      if (isEditing) {
        // Actualizar cuenta existente
        await (db.update(db.accounts)
              ..where((a) => a.id.equals(widget.account!.id)))
            .write(AccountsCompanion(
          name: Value(name),
          icon: Value(selectedIcon),
          color: Value(selectedColor),
          categoryId: Value(categoryId!),
          balance: Value(balance),
          description: Value(description.isEmpty ? null : description),
          includeInTotal: Value(includeInTotal),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        // Crear nueva cuenta
        await db.into(db.accounts).insert(AccountsCompanion(
              id: Value(const Uuid().v4()),
              name: Value(name),
              icon: Value(selectedIcon),
              color: Value(selectedColor),
              categoryId: Value(categoryId!),
              balance: Value(balance),
              currency: const Value('COP'),
              description: Value(description.isEmpty ? null : description),
              includeInTotal: Value(includeInTotal),
              isActive: const Value(true),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ));
      }

      if (mounted) {
        // Feedback háptico de éxito
        HapticFeedback.mediumImpact();

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Cuenta actualizada' : 'Cuenta creada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta cuenta? '
          'Las transacciones asociadas quedarán sin cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      final db = ref.read(appDatabaseProvider);

      try {
        await (db.delete(db.accounts)
              ..where((a) => a.id.equals(widget.account!.id)))
            .go();

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta eliminada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se puede eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Formateador de miles para el campo de monto
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final _numberFormat = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numValue = int.tryParse(newValue.text.replaceAll('.', ''));
    if (numValue == null) {
      return oldValue;
    }

    final formatted = _numberFormat.format(numValue);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
