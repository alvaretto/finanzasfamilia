import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/presentation/screens/statistics_screen.dart';

void main() {
  group('StatisticsScreen', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('es', 'CO'),
            Locale('es'),
          ],
          locale: Locale('es', 'CO'),
          home: StatisticsScreen(),
        ),
      );
    }

    testWidgets('muestra título Estadísticas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Estadísticas'), findsOneWidget);
    });

    testWidgets('muestra 3 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Tendencia'), findsOneWidget);
      expect(find.text('Comparar'), findsOneWidget);
    });

    testWidgets('tab Gastos muestra contenido', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Por defecto está en tab Gastos - muestra distribución por categoría
      expect(find.text('Distribución por categoría'), findsOneWidget);
    });

    testWidgets('puede navegar a tab Tendencia', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tendencia'));
      await tester.pumpAndSettle();

      expect(find.text('Tendencia de 6 meses'), findsOneWidget);
    });

    testWidgets('puede navegar a tab Comparar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comparar'));
      await tester.pumpAndSettle();

      // El tab Comparar muestra la tarjeta de comparación y análisis
      expect(find.text('Comparado con el mes anterior'), findsOneWidget);
    });

    testWidgets('tab Comparar muestra análisis', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comparar'));
      await tester.pumpAndSettle();

      expect(find.text('Análisis'), findsOneWidget);
    });

    testWidgets('tiene TabController funcional', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tab a Tendencia
      await tester.tap(find.text('Tendencia'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresos vs Gastos'), findsOneWidget);

      // Tab a Comparar
      await tester.tap(find.text('Comparar'));
      await tester.pumpAndSettle();
      expect(find.text('Analiza tu progreso financiero'), findsOneWidget);

      // Tab de vuelta a Gastos - usa byType para evitar ambigüedad
      await tester.tap(find.byType(Tab).first);
      await tester.pumpAndSettle();
      expect(find.text('Distribución por categoría'), findsOneWidget);
    });
  });
}
