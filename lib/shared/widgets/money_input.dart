import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters/currency_formatter.dart';

/// Widget para entrada de montos con formato de moneda
class MoneyInput extends StatefulWidget {
  final double? initialValue;
  final String currency;
  final String locale;
  final ValueChanged<double> onChanged;
  final String? label;
  final String? hint;
  final bool autofocus;
  final bool showSymbol;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(double?)? validator;

  const MoneyInput({
    super.key,
    this.initialValue,
    this.currency = 'MXN',
    this.locale = 'es_MX',
    required this.onChanged,
    this.label,
    this.hint,
    this.autofocus = false,
    this.showSymbol = true,
    this.controller,
    this.focusNode,
    this.validator,
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    if (widget.initialValue != null && widget.initialValue! > 0) {
      _controller.text = _formatValue(widget.initialValue!);
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    if (!_focusNode.hasFocus) {
      // Al perder foco, formatear el valor
      final value = _parseValue(_controller.text);
      if (value != null && value > 0) {
        _controller.text = _formatValue(value);
      }
      _validate(value);
    } else {
      // Al ganar foco, mostrar solo numeros
      final value = _parseValue(_controller.text);
      if (value != null && value > 0) {
        _controller.text = value.toStringAsFixed(2);
        // Seleccionar todo el texto
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    }
  }

  String _formatValue(double value) {
    return CurrencyFormatter.format(
      value,
      currency: widget.currency,
      locale: widget.locale,
      showSymbol: widget.showSymbol,
    );
  }

  double? _parseValue(String text) {
    return CurrencyFormatter.parse(text, locale: widget.locale);
  }

  void _validate(double? value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = widget.showSymbol
        ? CurrencyFormatter.supportedCurrencies
            .firstWhere(
              (c) => c.code == widget.currency,
              orElse: () => CurrencyFormatter.supportedCurrencies.first,
            )
            .symbol
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          decoration: InputDecoration(
            prefixIcon: symbol.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Text(
                      symbol,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            hintText: widget.hint ?? '0.00',
            hintStyle: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            errorText: _errorText,
            filled: true,
            fillColor: _hasFocus
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          onChanged: (value) {
            final parsed = _parseValue(value);
            if (parsed != null) {
              widget.onChanged(parsed);
              _validate(parsed);
            } else if (value.isEmpty) {
              widget.onChanged(0.0);
              _validate(0.0);
            }
          },
        ),
      ],
    );
  }
}

/// Widget de botones rapidos para montos comunes
class QuickAmountButtons extends StatelessWidget {
  final List<double> amounts;
  final String currency;
  final String locale;
  final ValueChanged<double> onSelected;

  const QuickAmountButtons({
    super.key,
    this.amounts = const [50, 100, 200, 500, 1000],
    this.currency = 'MXN',
    this.locale = 'es_MX',
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: amounts.map((amount) {
        return ActionChip(
          label: Text(
            CurrencyFormatter.format(
              amount,
              currency: currency,
              locale: locale,
              showSymbol: true,
              decimalDigits: 0,
            ),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          onPressed: () => onSelected(amount),
        );
      }).toList(),
    );
  }
}
