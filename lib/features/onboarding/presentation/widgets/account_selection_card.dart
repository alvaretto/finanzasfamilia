import 'package:flutter/material.dart';
import '../../models/account_template.dart';
import '../../../../core/theme/app_theme.dart';

/// Tarjeta de selección de cuenta para el wizard de onboarding
/// Muestra el template de cuenta con checkbox, icono, nombre y descripción
class AccountSelectionCard extends StatelessWidget {
  final AccountTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountSelectionCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = Color(int.parse(template.defaultColor.replaceFirst('#', '0xFF')));

    return Card(
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected ? selectedColor.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? selectedColor : colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? selectedColor.withValues(alpha: 0.08) : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Checkbox circular
              _buildCheckbox(context, selectedColor),

              const SizedBox(width: 16),

              // Emoji/Icon container
              _buildIconContainer(context, selectedColor),

              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: _buildTextContent(context, selectedColor),
              ),

              // Flecha indicadora
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: selectedColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, Color selectedColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? selectedColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? selectedColor : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildIconContainer(BuildContext context, Color selectedColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        template.emoji,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, Color selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          template.defaultName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? selectedColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          template.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        // Mostrar sugerencias si las hay y está seleccionado
        if (isSelected && template.suggestedNames != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: template.suggestedNames!.take(3).map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: selectedColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Versión compacta de la tarjeta para listas más densas
class AccountSelectionChip extends StatelessWidget {
  final AccountTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountSelectionChip({
    required this.template,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(int.parse(template.defaultColor.replaceFirst('#', '0xFF')));

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Text(template.emoji),
      label: Text(template.defaultName),
      selectedColor: selectedColor.withValues(alpha: 0.15),
      checkmarkColor: selectedColor,
      labelStyle: TextStyle(
        color: isSelected ? selectedColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      side: BorderSide(
        color: isSelected ? selectedColor : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
