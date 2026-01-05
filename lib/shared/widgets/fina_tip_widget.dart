import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../services/contextual_tips_service.dart';

/// Widget que muestra un consejo contextual de Fina
class FinaTipWidget extends StatelessWidget {
  final FinaTip tip;
  final VoidCallback? onDismiss;

  const FinaTipWidget({
    super.key,
    required this.tip,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(tip.context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con emoji y título
            Row(
              children: [
                Text(
                  tip.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tip.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(tip.context),
                        ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: _getTextColor(tip.context).withValues(alpha: 0.6),
                    ),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Mensaje
            Text(
              tip.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getTextColor(tip.context).withValues(alpha: 0.9),
                  ),
            ),

            // Botón de acción (si existe)
            if (tip.actionText != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (tip.actionRoute != null) {
                      context.push(tip.actionRoute!);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _getTextColor(tip.context),
                    side: BorderSide(
                      color: _getTextColor(tip.context).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(tip.actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(TipContext context) {
    switch (context) {
      case TipContext.welcome:
        return AppColors.primary.withValues(alpha: 0.1);
      case TipContext.budgetExceeded:
      case TipContext.highExpense:
      case TipContext.lowFinancialHealth:
        return AppColors.error.withValues(alpha: 0.1);
      case TipContext.budgetNearLimit:
      case TipContext.antExpenses:
        return AppColors.warning.withValues(alpha: 0.1);
      case TipContext.goalNearCompletion:
      case TipContext.goodSavingsStreak:
      case TipContext.goodFinancialHealth:
        return AppColors.income.withValues(alpha: 0.1);
      case TipContext.highDebt:
        return AppColors.expense.withValues(alpha: 0.1);
      case TipContext.general:
        return AppColors.info.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(TipContext context) {
    switch (context) {
      case TipContext.welcome:
        return AppColors.primary;
      case TipContext.budgetExceeded:
      case TipContext.highExpense:
      case TipContext.lowFinancialHealth:
        return AppColors.error;
      case TipContext.budgetNearLimit:
      case TipContext.antExpenses:
        return AppColors.warning;
      case TipContext.goalNearCompletion:
      case TipContext.goodSavingsStreak:
      case TipContext.goodFinancialHealth:
        return AppColors.income;
      case TipContext.highDebt:
        return AppColors.expense;
      case TipContext.general:
        return AppColors.info;
    }
  }
}

/// Widget compacto de Fina (solo icono + título, expandible)
class FinaTipCompact extends StatefulWidget {
  final FinaTip tip;

  const FinaTipCompact({
    super.key,
    required this.tip,
  });

  @override
  State<FinaTipCompact> createState() => _FinaTipCompactState();
}

class _FinaTipCompactState extends State<FinaTipCompact> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(widget.tip.context),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Row(
                children: [
                  Text(
                    widget.tip.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.tip.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTextColor(widget.tip.context),
                          ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _getTextColor(widget.tip.context).withValues(alpha: 0.6),
                  ),
                ],
              ),

              // Contenido expandido
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.tip.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getTextColor(widget.tip.context)
                            .withValues(alpha: 0.8),
                      ),
                ),
                if (widget.tip.actionText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      if (widget.tip.actionRoute != null) {
                        context.push(widget.tip.actionRoute!);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _getTextColor(widget.tip.context),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(widget.tip.actionText!),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(TipContext context) {
    switch (context) {
      case TipContext.welcome:
        return AppColors.primary.withValues(alpha: 0.1);
      case TipContext.budgetExceeded:
      case TipContext.highExpense:
      case TipContext.lowFinancialHealth:
        return AppColors.error.withValues(alpha: 0.1);
      case TipContext.budgetNearLimit:
      case TipContext.antExpenses:
        return AppColors.warning.withValues(alpha: 0.1);
      case TipContext.goalNearCompletion:
      case TipContext.goodSavingsStreak:
      case TipContext.goodFinancialHealth:
        return AppColors.income.withValues(alpha: 0.1);
      case TipContext.highDebt:
        return AppColors.expense.withValues(alpha: 0.1);
      case TipContext.general:
        return AppColors.info.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(TipContext context) {
    switch (context) {
      case TipContext.welcome:
        return AppColors.primary;
      case TipContext.budgetExceeded:
      case TipContext.highExpense:
      case TipContext.lowFinancialHealth:
        return AppColors.error;
      case TipContext.budgetNearLimit:
      case TipContext.antExpenses:
        return AppColors.warning;
      case TipContext.goalNearCompletion:
      case TipContext.goodSavingsStreak:
      case TipContext.goodFinancialHealth:
        return AppColors.income;
      case TipContext.highDebt:
        return AppColors.expense;
      case TipContext.general:
        return AppColors.info;
    }
  }
}
