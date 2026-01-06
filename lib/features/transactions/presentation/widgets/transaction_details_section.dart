import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/payment_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/icon_utils.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../domain/models/establishment_model.dart';
import '../../domain/models/unit_model.dart';
import '../providers/establishments_provider.dart';
import '../providers/units_provider.dart';

/// Widget expandible para detalles adicionales de transacción
class TransactionDetailsSection extends ConsumerStatefulWidget {
  final String? initialItemDescription;
  final String? initialBrand;
  final double? initialQuantity;
  final String? initialUnitId;
  final String? initialEstablishmentId;
  final String? initialPaymentMethod;
  final String? initialPaymentMedium;
  final String? initialPaymentSubmedium;
  final AccountModel? selectedAccount;
  final Function(TransactionDetails) onDetailsChanged;

  const TransactionDetailsSection({
    super.key,
    this.initialItemDescription,
    this.initialBrand,
    this.initialQuantity,
    this.initialUnitId,
    this.initialEstablishmentId,
    this.initialPaymentMethod,
    this.initialPaymentMedium,
    this.initialPaymentSubmedium,
    this.selectedAccount,
    required this.onDetailsChanged,
  });

  @override
  ConsumerState<TransactionDetailsSection> createState() =>
      _TransactionDetailsSectionState();
}

class _TransactionDetailsSectionState
    extends ConsumerState<TransactionDetailsSection> {
  bool _isExpanded = false;

  final _itemDescriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _establishmentSearchController = TextEditingController();

  String? _selectedUnitId;
  String? _selectedEstablishmentId;
  PaymentMethod? _selectedPaymentMethod;
  PaymentMedium? _selectedPaymentMedium;
  String? _selectedPaymentSubmedium;

  List<EstablishmentModel> _filteredEstablishments = [];
  bool _showEstablishmentDropdown = false;

  @override
  void initState() {
    super.initState();

    _itemDescriptionController.text = widget.initialItemDescription ?? '';
    _brandController.text = widget.initialBrand ?? '';
    if (widget.initialQuantity != null) {
      _quantityController.text = widget.initialQuantity!.toString();
    }
    _selectedUnitId = widget.initialUnitId;
    _selectedEstablishmentId = widget.initialEstablishmentId;
    _selectedPaymentMethod =
        PaymentMethod.fromValue(widget.initialPaymentMethod);
    _selectedPaymentMedium =
        PaymentMedium.fromValue(widget.initialPaymentMedium);
    _selectedPaymentSubmedium = widget.initialPaymentSubmedium;

    // Expandir si ya hay datos
    if (_hasAnyData()) {
      _isExpanded = true;
    }

    // Auto-sugerir pago basado en cuenta
    _autoSuggestPayment();
  }

  bool _hasAnyData() {
    return widget.initialItemDescription != null ||
        widget.initialBrand != null ||
        widget.initialQuantity != null ||
        widget.initialUnitId != null ||
        widget.initialEstablishmentId != null ||
        widget.initialPaymentMethod != null;
  }

  void _autoSuggestPayment() {
    if (widget.selectedAccount != null && _selectedPaymentMethod == null) {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
        widget.selectedAccount!.type.name,
        widget.selectedAccount!.name,
      );
      setState(() {
        _selectedPaymentMethod = suggestion.method;
        _selectedPaymentMedium = suggestion.medium;
        _selectedPaymentSubmedium = suggestion.submedium;
      });
      // Diferir notificación para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notifyChanges();
        }
      });
    }
  }

  @override
  void didUpdateWidget(TransactionDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccount != oldWidget.selectedAccount) {
      // Diferir para evitar setState durante build del parent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _autoSuggestPayment();
        }
      });
    }
  }

  @override
  void dispose() {
    _itemDescriptionController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _establishmentSearchController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onDetailsChanged(TransactionDetails(
      itemDescription: _itemDescriptionController.text.isEmpty
          ? null
          : _itemDescriptionController.text,
      brand: _brandController.text.isEmpty ? null : _brandController.text,
      quantity: double.tryParse(_quantityController.text),
      unitId: _selectedUnitId,
      establishmentId: _selectedEstablishmentId,
      paymentMethod: _selectedPaymentMethod?.value,
      paymentMedium: _selectedPaymentMedium?.value,
      paymentSubmedium: _selectedPaymentSubmedium,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Header expandible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles adicionales',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _isExpanded
                              ? 'Artículo, establecimiento, forma de pago'
                              : 'Toca para agregar más detalles',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // === SECCIÓN: Detalle del Artículo ===
          _buildSectionTitle(context, 'Detalle del artículo', Icons.inventory_2),
          const SizedBox(height: AppSpacing.sm),

          // Descripción del ítem
          TextFormField(
            controller: _itemDescriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿Qué compraste?',
              hintText: 'ej. Arroz Diana',
              prefixIcon: Icon(Icons.shopping_basket),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Marca
          TextFormField(
            controller: _brandController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Marca (opcional)',
              hintText: 'ej. Diana, Ramo, etc.',
              prefixIcon: Icon(Icons.label),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cantidad y Unidad (lado a lado)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,3}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    hintText: '1',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  onChanged: (_) => _notifyChanges(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: _buildUnitSelector(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // === SECCIÓN: Establecimiento ===
          _buildSectionTitle(context, 'Lugar de compra', Icons.place),
          const SizedBox(height: AppSpacing.sm),
          _buildEstablishmentField(),
          const SizedBox(height: AppSpacing.lg),

          // === SECCIÓN: Forma de Pago ===
          _buildSectionTitle(context, 'Forma de pago', Icons.payment),
          const SizedBox(height: AppSpacing.sm),
          _buildPaymentMethodSelector(),
          const SizedBox(height: AppSpacing.sm),
          _buildPaymentMediumSelector(),
          if (_selectedPaymentMedium?.requiresSubmedium ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildPaymentSubmediumSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector() {
    final unitsState = ref.watch(unitsProvider);

    if (unitsState.isLoading) {
      return const LinearProgressIndicator();
    }

    final groupedUnits = ref.watch(unitsGroupedProvider);

    return DropdownButtonFormField<String>(
      value: _selectedUnitId,
      decoration: const InputDecoration(
        labelText: 'Unidad',
        prefixIcon: Icon(Icons.straighten),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Sin especificar'),
        ),
        ...groupedUnits.entries.expand((entry) {
          final category = UnitCategory.fromValue(entry.key);
          return [
            DropdownMenuItem<String>(
              enabled: false,
              value: 'header_${entry.key}',
              child: Text(
                category.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...entry.value.map((unit) => DropdownMenuItem(
                  value: unit.id,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Text(unit.displayNameWithShort),
                  ),
                )),
          ];
        }),
      ],
      onChanged: (value) {
        if (value != null && !value.startsWith('header_')) {
          setState(() => _selectedUnitId = value);
          _notifyChanges();
        }
      },
    );
  }

  Widget _buildEstablishmentField() {
    final establishmentsState = ref.watch(establishmentsProvider);

    return Column(
      children: [
        TextFormField(
          controller: _establishmentSearchController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Establecimiento',
            hintText: 'ej. Éxito, D1, Tienda del barrio',
            prefixIcon: const Icon(Icons.store),
            suffixIcon: _selectedEstablishmentId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedEstablishmentId = null;
                        _establishmentSearchController.clear();
                        _filteredEstablishments = [];
                        _showEstablishmentDropdown = false;
                      });
                      _notifyChanges();
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            if (query.isEmpty) {
              setState(() {
                _filteredEstablishments = [];
                _showEstablishmentDropdown = false;
              });
            } else {
              setState(() {
                _filteredEstablishments = establishmentsState.search(query);
                _showEstablishmentDropdown = true;
              });
            }
          },
          onTap: () {
            if (_establishmentSearchController.text.isNotEmpty) {
              setState(() {
                _filteredEstablishments = establishmentsState
                    .search(_establishmentSearchController.text);
                _showEstablishmentDropdown = true;
              });
            }
          },
        ),

        // Dropdown de sugerencias
        if (_showEstablishmentDropdown && _filteredEstablishments.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredEstablishments.length,
              itemBuilder: (context, index) {
                final est = _filteredEstablishments[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    IconUtils.fromName(est.displayIcon),
                    size: 20,
                  ),
                  title: Text(est.name),
                  subtitle:
                      est.address != null ? Text(est.address!) : null,
                  onTap: () => _selectEstablishment(est),
                );
              },
            ),
          ),

        // Botón para crear nuevo si no existe
        if (_showEstablishmentDropdown &&
            _filteredEstablishments.isEmpty &&
            _establishmentSearchController.text.isNotEmpty)
          ListTile(
            dense: true,
            leading: Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Crear "${_establishmentSearchController.text}"',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onTap: () => _createNewEstablishment(
                _establishmentSearchController.text),
          ),
      ],
    );
  }

  void _selectEstablishment(EstablishmentModel est) {
    setState(() {
      _selectedEstablishmentId = est.id;
      _establishmentSearchController.text = est.name;
      _showEstablishmentDropdown = false;
      _filteredEstablishments = [];
    });
    _notifyChanges();
  }

  Future<void> _createNewEstablishment(String name) async {
    final notifier = ref.read(establishmentsProvider.notifier);
    final newEst = await notifier.getOrCreate(name: name);

    setState(() {
      _selectedEstablishmentId = newEst.id;
      _establishmentSearchController.text = newEst.name;
      _showEstablishmentDropdown = false;
      _filteredEstablishments = [];
    });
    _notifyChanges();
  }

  Widget _buildPaymentMethodSelector() {
    return SegmentedButton<PaymentMethod>(
      segments: PaymentMethod.values.map((method) {
        return ButtonSegment(
          value: method,
          label: Text(method.displayName),
          icon: Icon(
            method == PaymentMethod.credit
                ? Icons.credit_score
                : Icons.payments,
          ),
        );
      }).toList(),
      selected: _selectedPaymentMethod != null
          ? {_selectedPaymentMethod!}
          : {},
      onSelectionChanged: (selection) {
        setState(() {
          _selectedPaymentMethod = selection.first;
          _selectedPaymentMedium = null;
          _selectedPaymentSubmedium = null;
        });
        _notifyChanges();
      },
      emptySelectionAllowed: true,
    );
  }

  Widget _buildPaymentMediumSelector() {
    final availableMediums = _selectedPaymentMethod != null
        ? PaymentMedium.forMethod(_selectedPaymentMethod!)
        : PaymentMedium.values;

    return DropdownButtonFormField<PaymentMedium>(
      value: _selectedPaymentMedium,
      decoration: const InputDecoration(
        labelText: 'Medio de pago',
        prefixIcon: Icon(Icons.credit_card),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Sin especificar'),
        ),
        ...availableMediums.map((medium) {
          return DropdownMenuItem(
            value: medium,
            child: Row(
              children: [
                Icon(IconUtils.fromName(medium.icon), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(medium.displayName),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPaymentMedium = value;
          _selectedPaymentSubmedium = null;
        });
        _notifyChanges();
      },
    );
  }

  Widget _buildPaymentSubmediumSelector() {
    final List<({String value, String displayName, String icon})> submediums;

    if (_selectedPaymentMedium == PaymentMedium.bankTransfer) {
      submediums = BankTransferProvider.values
          .map((b) => (value: b.value, displayName: b.displayName, icon: b.icon))
          .toList();
    } else if (_selectedPaymentMedium == PaymentMedium.appTransfer) {
      submediums = AppTransferProvider.values
          .map((a) => (value: a.value, displayName: a.displayName, icon: a.icon))
          .toList();
    } else {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      value: _selectedPaymentSubmedium,
      decoration: InputDecoration(
        labelText: _selectedPaymentMedium == PaymentMedium.bankTransfer
            ? 'Banco'
            : 'App de pago',
        prefixIcon: Icon(
          _selectedPaymentMedium == PaymentMedium.bankTransfer
              ? Icons.account_balance
              : Icons.smartphone,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Sin especificar'),
        ),
        ...submediums.map((sub) {
          return DropdownMenuItem(
            value: sub.value,
            child: Row(
              children: [
                Icon(IconUtils.fromName(sub.icon), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(sub.displayName),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() => _selectedPaymentSubmedium = value);
        _notifyChanges();
      },
    );
  }
}

/// Clase para transportar los detalles de la transacción
class TransactionDetails {
  final String? itemDescription;
  final String? brand;
  final double? quantity;
  final String? unitId;
  final String? establishmentId;
  final String? paymentMethod;
  final String? paymentMedium;
  final String? paymentSubmedium;

  const TransactionDetails({
    this.itemDescription,
    this.brand,
    this.quantity,
    this.unitId,
    this.establishmentId,
    this.paymentMethod,
    this.paymentMedium,
    this.paymentSubmedium,
  });

  /// Calcular precio unitario dado el monto total
  double? calculateUnitPrice(double totalAmount) {
    if (quantity != null && quantity! > 0) {
      return totalAmount / quantity!;
    }
    return null;
  }

  bool get hasData =>
      itemDescription != null ||
      brand != null ||
      quantity != null ||
      unitId != null ||
      establishmentId != null ||
      paymentMethod != null;
}
