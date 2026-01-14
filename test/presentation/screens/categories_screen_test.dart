import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/categories_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('CategoriesScreen', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);
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
          home: CategoriesScreen(),
        ),
      );
    }

    testWidgets('muestra título Categorías', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('muestra selector de tipo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Activos'), findsOneWidget);
    });

    testWidgets('muestra lista de categorías', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que la pantalla carga y hay una ListView
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('segmento de ingresos es interactivo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El segmento de Ingresos debe existir
      expect(find.text('Ingresos'), findsOneWidget);

      // Tocar el segmento
      await tester.tap(find.text('Ingresos'));
      await tester.pumpAndSettle();

      // La pantalla sigue mostrando el SegmentedButton
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('segmento de activos es interactivo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El segmento de Activos debe existir
      expect(find.text('Activos'), findsOneWidget);

      // Tocar el segmento
      await tester.tap(find.text('Activos'));
      await tester.pumpAndSettle();

      // La pantalla sigue mostrando el SegmentedButton
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });
  });

  group('selectedCategoryTypeProvider', () {
    test('valor inicial es expense', () {
      final container = ProviderContainer();
      expect(container.read(selectedCategoryTypeProvider), equals('expense'));
      container.dispose();
    });

    test('puede cambiar tipo', () {
      final container = ProviderContainer();

      container.read(selectedCategoryTypeProvider.notifier).state = 'income';
      expect(container.read(selectedCategoryTypeProvider), equals('income'));

      container.read(selectedCategoryTypeProvider.notifier).state = 'asset';
      expect(container.read(selectedCategoryTypeProvider), equals('asset'));

      container.dispose();
    });
  });

  group('expandedCategoryProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(expandedCategoryProvider), isNull);
      container.dispose();
    });

    test('puede expandir categoría', () {
      final container = ProviderContainer();

      container.read(expandedCategoryProvider.notifier).state = 'cat-123';
      expect(container.read(expandedCategoryProvider), equals('cat-123'));

      container.read(expandedCategoryProvider.notifier).state = null;
      expect(container.read(expandedCategoryProvider), isNull);

      container.dispose();
    });
  });
}
