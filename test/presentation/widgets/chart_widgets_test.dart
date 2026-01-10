import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:finanzas_familiares/domain/services/chart_service.dart';
import 'package:finanzas_familiares/presentation/widgets/expense_pie_chart.dart';
import 'package:finanzas_familiares/presentation/widgets/monthly_trend_chart.dart';
import 'package:finanzas_familiares/presentation/widgets/month_comparison_card.dart';

void main() {
  group('ExpensePieChart', () {
    Widget createWidget(List<CategoryExpenseData> data) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'CO')],
        locale: const Locale('es', 'CO'),
        home: Scaffold(
          body: ExpensePieChart(data: data),
        ),
      );
    }

    testWidgets('muestra mensaje cuando no hay datos', (tester) async {
      await tester.pumpWidget(createWidget([]));
      await tester.pumpAndSettle();

      expect(find.text('Sin gastos este mes'), findsOneWidget);
    });

    testWidgets('muestra gráfico con datos', (tester) async {
      final data = [
        const CategoryExpenseData(
          categoryId: '1',
          categoryName: 'Alimentación',
          amount: 500000,
          percentage: 50,
          color: 0xFF4CAF50,
        ),
        const CategoryExpenseData(
          categoryId: '2',
          categoryName: 'Transporte',
          amount: 300000,
          percentage: 30,
          color: 0xFF2196F3,
        ),
        const CategoryExpenseData(
          categoryId: '3',
          categoryName: 'Servicios',
          amount: 200000,
          percentage: 20,
          color: 0xFFF44336,
        ),
      ];

      await tester.pumpWidget(createWidget(data));
      await tester.pumpAndSettle();

      // Verifica que se muestran las categorías en la leyenda
      expect(find.textContaining('Alimentación'), findsOneWidget);
      expect(find.textContaining('Transporte'), findsOneWidget);
      expect(find.textContaining('Servicios'), findsOneWidget);
    });

    testWidgets('respeta altura personalizada', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ExpensePieChart(data: [], height: 400),
        ),
      ));
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 400);
    });
  });

  group('MonthlyTrendChart', () {
    Widget createWidget(List<MonthlyTrendData> data) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'CO')],
        locale: const Locale('es', 'CO'),
        home: Scaffold(
          body: MonthlyTrendChart(data: data),
        ),
      );
    }

    testWidgets('muestra mensaje cuando no hay datos', (tester) async {
      await tester.pumpWidget(createWidget([]));
      await tester.pumpAndSettle();

      expect(find.text('Sin datos de tendencia'), findsOneWidget);
    });

    testWidgets('muestra leyenda con datos', (tester) async {
      final data = [
        MonthlyTrendData(
          month: DateTime(2026, 1, 1),
          income: 1000000,
          expense: 800000,
          balance: 200000,
        ),
        MonthlyTrendData(
          month: DateTime(2026, 2, 1),
          income: 1100000,
          expense: 850000,
          balance: 250000,
        ),
      ];

      await tester.pumpWidget(createWidget(data));
      await tester.pumpAndSettle();

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('puede ocultar línea de balance', (tester) async {
      final data = [
        MonthlyTrendData(
          month: DateTime(2026, 1, 1),
          income: 1000000,
          expense: 800000,
          balance: 200000,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MonthlyTrendChart(data: data, showBalance: false),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Balance'), findsNothing);
    });
  });

  group('MonthComparisonCard', () {
    Widget createWidget(PeriodComparison comparison) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'CO')],
        locale: const Locale('es', 'CO'),
        home: Scaffold(
          body: MonthComparisonCard(comparison: comparison),
        ),
      );
    }

    testWidgets('muestra título comparativo', (tester) async {
      const comparison = PeriodComparison(
        currentIncome: 1000000,
        previousIncome: 900000,
        incomeChange: 100000,
        incomeChangePercent: 11.1,
        currentExpense: 800000,
        previousExpense: 850000,
        expenseChange: -50000,
        expenseChangePercent: -5.9,
      );

      await tester.pumpWidget(createWidget(comparison));
      await tester.pumpAndSettle();

      expect(find.text('Comparado con el mes anterior'), findsOneWidget);
    });

    testWidgets('muestra secciones de ingresos y gastos', (tester) async {
      const comparison = PeriodComparison(
        currentIncome: 1000000,
        previousIncome: 900000,
        incomeChange: 100000,
        incomeChangePercent: 11.1,
        currentExpense: 800000,
        previousExpense: 850000,
        expenseChange: -50000,
        expenseChangePercent: -5.9,
      );

      await tester.pumpWidget(createWidget(comparison));
      await tester.pumpAndSettle();

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
    });

    testWidgets('muestra porcentaje de cambio', (tester) async {
      const comparison = PeriodComparison(
        currentIncome: 1000000,
        previousIncome: 900000,
        incomeChange: 100000,
        incomeChangePercent: 11.1,
        currentExpense: 800000,
        previousExpense: 850000,
        expenseChange: -50000,
        expenseChangePercent: -5.9,
      );

      await tester.pumpWidget(createWidget(comparison));
      await tester.pumpAndSettle();

      expect(find.textContaining('11.1%'), findsOneWidget);
      expect(find.textContaining('-5.9%'), findsOneWidget);
    });

    testWidgets('muestra íconos de tendencia', (tester) async {
      const comparison = PeriodComparison(
        currentIncome: 1000000,
        previousIncome: 900000,
        incomeChange: 100000,
        incomeChangePercent: 11.1,
        currentExpense: 800000,
        previousExpense: 850000,
        expenseChange: -50000,
        expenseChangePercent: -5.9,
      );

      await tester.pumpWidget(createWidget(comparison));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });
  });
}
