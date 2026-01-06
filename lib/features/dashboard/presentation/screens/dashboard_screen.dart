import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/utils/motivational_messages.dart';
import '../../../../shared/widgets/budget_503020_widget.dart';
import '../../../../shared/services/budget_503020_service.dart';
import '../../../../shared/widgets/financial_health_widget.dart';
import '../../../../shared/services/financial_health_service.dart';
import '../../../../shared/widgets/ant_expense_widget.dart';
import '../../../../shared/services/ant_expense_service.dart';
import '../../../../shared/utils/ant_expense_analysis.dart';
import '../../../../shared/widgets/fina_tip_widget.dart';
import '../../../../shared/services/contextual_tips_service.dart';
import '../../../../shared/widgets/month_comparison_widget.dart';
import '../../../../shared/utils/month_comparison.dart';
import '../../../../shared/widgets/upcoming_payments_widget.dart';
import '../../../../shared/utils/upcoming_payments.dart';
import '../../../../shared/utils/icon_utils.dart';
import '../../../../shared/services/notification_aggregator_service.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas Familiares'),
        actions: [
          _buildNotificationBell(context, ref),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Limpiar duplicados al refrescar
          await ref.read(accountsProvider.notifier).cleanDuplicates();
          await ref.read(accountsProvider.notifier).syncAccounts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo personalizado
              _buildGreeting(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // Mensaje motivacional
              _buildMotivationalMessage(context),
              const SizedBox(height: AppSpacing.lg),

              // 💡 Consejo contextual de Fina
              _buildFinaTip(context, ref),

              // 💰 Tus Cuentas (balance total con desglose)
              _buildBalanceCard(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // 📊 Este Mes (ingresos, gastos, disponible)
              _buildQuickStats(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // 📅 Próximos Pagos
              _buildUpcomingPaymentsWidget(context, ref),

              // 📊 Widget Regla 50/30/20
              _build503020Widget(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // 🏥 Salud Financiera
              _buildFinancialHealthWidget(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // 📊 Comparación Mensual
              _buildMonthComparisonWidget(context, ref),

              // 🐜 Gastos Hormiga (solo si hay gastos significativos)
              _buildAntExpenseWidget(context, ref),

              // Grafico de gastos por categoría
              _buildExpenseChart(context, ref),
              const SizedBox(height: AppSpacing.lg),

              // Ultimas transacciones
              _buildRecentTransactions(context, ref),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.aiChat),
        icon: const Icon(Icons.smart_toy),
        label: const Text('Fina'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final accountsState = ref.watch(accountsProvider);
    final budgetsState = ref.watch(budgetsProvider);
    final goalsState = ref.watch(goalsProvider);

    // Obtener datos
    final transactions = transactionsState.transactions;
    final accounts = accountsState.accounts;
    final budgets = budgetsState.budgets;
    final goals = goalsState.activeGoals;

    // Calcular análisis
    final financialHealth = FinancialHealthService.calculate(
      accounts: accounts,
      transactions: transactions,
      monthlyIncome: transactionsState.totalIncome,
      monthlyExpenses: transactionsState.totalExpenses,
    );

    final antExpenseAnalysis =
        AntExpenseService.analyzeCurrentMonth(transactions);

    // Generar notificaciones
    final notifications = NotificationAggregatorService.generateNotifications(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      accounts: accounts,
      financialHealth: financialHealth,
      antExpenseAnalysis: antExpenseAnalysis,
    );

    final unreadCount = notifications.length;
    final hasHighPriority =
        NotificationAggregatorService.hasHighPriority(notifications);

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            hasHighPriority
                ? Icons.notifications_active
                : Icons.notifications_outlined,
          ),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: hasHighPriority ? AppColors.error : AppColors.warning,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos dias';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    // Obtener nombre del usuario desde Supabase Auth
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Usuario';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        Text(
          userName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(BuildContext context) {
    // Por ahora mostrar tip del día
    // TODO: Calcular métricas reales cuando estén disponibles
    final message = MotivationalMessages.getTipOfTheDay(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build503020Widget(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);

    // Calcular ingresos del mes actual
    final monthlyIncome = transactionsState.totalIncome;

    // Obtener transacciones del mes actual
    final transactions = transactionsState.transactions;

    // Calcular presupuesto 50/30/20
    final budget = Budget503020Service.calculate(
      transactions: transactions,
      monthlyIncome: monthlyIncome,
    );

    // Si no hay ingresos, no mostrar el widget
    if (monthlyIncome == 0) {
      return const SizedBox.shrink();
    }

    return Budget503020Widget(budget: budget);
  }

  Widget _buildFinancialHealthWidget(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final accountsState = ref.watch(accountsProvider);

    // Calcular métricas
    final monthlyIncome = transactionsState.totalIncome;
    final monthlyExpenses = transactionsState.totalExpenses;
    final accounts = accountsState.accounts;
    final transactions = transactionsState.transactions;

    // Calcular salud financiera
    final health = FinancialHealthService.calculate(
      accounts: accounts,
      transactions: transactions,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
    );

    // Si no hay datos suficientes, no mostrar el widget
    if (monthlyIncome == 0 && accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return FinancialHealthWidget(health: health);
  }

  Widget _buildUpcomingPaymentsWidget(BuildContext context, WidgetRef ref) {
    final budgetsState = ref.watch(budgetsProvider);
    final budgets = budgetsState.budgets;

    // Obtener próximos pagos desde presupuestos
    final upcomingPayments = UpcomingPaymentsService.getUpcomingFromBudgets(budgets);

    // No mostrar si no hay pagos próximos
    if (upcomingPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        UpcomingPaymentsWidget(payments: upcomingPayments),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildMonthComparisonWidget(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final transactions = transactionsState.transactions;

    // Calcular comparación mensual
    final comparison = MonthComparison.fromTransactions(transactions);

    // No mostrar si no hay datos del mes anterior
    if (comparison.previousTransactionCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        MonthComparisonWidget(comparison: comparison),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildFinaTip(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final accountsState = ref.watch(accountsProvider);
    final budgetsState = ref.watch(budgetsProvider);
    final goalsState = ref.watch(goalsProvider);

    // Obtener datos necesarios
    final transactions = transactionsState.transactions;
    final accounts = accountsState.accounts;
    final budgets = budgetsState.budgets;
    final goals = goalsState.activeGoals;
    final monthlyIncome = transactionsState.totalIncome;
    final monthlyExpenses = transactionsState.totalExpenses;

    // Calcular salud financiera
    final health = FinancialHealthService.calculate(
      accounts: accounts,
      transactions: transactions,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
    );

    // Calcular análisis de gastos hormiga
    final antExpenseAnalysis = AntExpenseService.analyzeCurrentMonth(transactions);

    // Obtener consejo contextual
    final tip = ContextualTipsService.getContextualTip(
      recentTransactions: transactions,
      budgets: budgets,
      goals: goals,
      financialHealth: health,
      antExpenseAnalysis: antExpenseAnalysis,
      isFirstTime: transactions.isEmpty && accounts.isEmpty,
    );

    // Si no hay consejo, no mostrar nada
    if (tip == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        FinaTipCompact(tip: tip),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    final transactionsState = ref.watch(transactionsProvider);

    // Usar cuentas únicas para evitar duplicados en la visualización
    final uniqueAccounts = accountsState.uniqueActiveAccounts;

    // Calcular balance total de cuentas activas únicas
    final totalBalance = uniqueAccounts
        .where((acc) => acc.includeInTotal)
        .fold(0.0, (sum, acc) => sum + acc.balance);

    // Obtener top 4 cuentas únicas con más balance
    final topAccounts = List.of(uniqueAccounts)
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final displayAccounts = topAccounts.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💰 Tus Cuentas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total disponible',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
          Text(
            '\$${totalBalance.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (displayAccounts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppSpacing.sm),
            ...displayAccounts.map((account) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconUtils.fromName(
                              account.icon,
                              fallback: Icons.account_balance,
                            ),
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${account.name}:',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '\$${account.balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildBalanceIndicator(
                context,
                icon: Icons.arrow_upward,
                label: 'Recibí',
                value: '\$${transactionsState.totalIncome.toStringAsFixed(0)}',
                color: AppColors.income,
              ),
              const SizedBox(width: AppSpacing.lg),
              _buildBalanceIndicator(
                context,
                icon: Icons.arrow_downward,
                label: 'Gasté',
                value: '\$${transactionsState.totalExpenses.toStringAsFixed(0)}',
                color: AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

    final monthlyIncome = transactionsState.totalIncome;
    final monthlyExpenses = transactionsState.totalExpenses;
    final available = monthlyIncome - monthlyExpenses;

    // Obtener nombre del mes en español
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final monthName = months[now.month - 1];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 Este Mes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '($monthName)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Llevamos $currentDay de $daysInMonth días',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          color: AppColors.income,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ingresos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      '\$${monthlyIncome.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.income,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          color: AppColors.expense,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gastos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      '\$${monthlyExpenses.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          available >= 0
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          color: available >= 0 ? AppColors.income : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Disponible',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      '\$${available.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: available >= 0 ? AppColors.income : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAntExpenseWidget(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final analysis = AntExpenseService.analyzeCurrentMonth(
      transactionsState.transactions,
    );

    // Solo mostrar si hay gastos hormiga significativos
    if (analysis.impact == AntExpenseImpact.none) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        AntExpenseWidget(analysis: analysis),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildExpenseChart(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final expenses = transactionsState.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Si no hay gastos, mostrar estado vacío
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gastos por Categoría',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.reports),
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sin gastos registrados',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Registra tu primer gasto para ver\nel análisis por categorías',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    }

    // Agrupar gastos por categoría
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      final category = expense.categoryName ?? 'Otros';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount.abs();
    }

    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limitar a 4 categorías principales
    final topCategories = sortedCategories.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastos por Categoría',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.reports),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final percentage = (category.value / total * 100).round();
                    return PieChartSectionData(
                      value: category.value,
                      title: '$percentage%',
                      color: AppColors.categoryColors[index % AppColors.categoryColors.length],
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: topCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return _LegendItem(
                  color: AppColors.categoryColors[index % AppColors.categoryColors.length],
                  label: category.key,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final recentTransactions = transactionsState.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Últimos Movimientos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.transactions),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recentTransactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sin movimientos',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Toca el botón + para registrar\ntu primera transacción',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTransactions.map((transaction) {
            final isExpense = transaction.type == TransactionType.expense;
            final icon = IconUtils.fromName(
              transaction.categoryIcon,
              fallback: isExpense ? Icons.shopping_cart : Icons.attach_money,
            );
            final formattedAmount = isExpense
                ? '-\$${transaction.amount.abs().toStringAsFixed(0)}'
                : '+\$${transaction.amount.abs().toStringAsFixed(0)}';
            final subtitle = _formatTransactionDate(transaction.date);

            return _TransactionItem(
              icon: icon,
              title: transaction.description ?? transaction.categoryName ?? 'Sin descripción',
              subtitle: subtitle,
              amount: formattedAmount,
              isExpense: isExpense,
            );
          }),
      ],
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) {
      return 'Hoy, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: isExpense ? AppColors.expense : AppColors.income,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isExpense ? AppColors.expense : AppColors.income,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
