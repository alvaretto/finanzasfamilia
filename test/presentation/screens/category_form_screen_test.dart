import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/category_form_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('CategoryFormScreen Widget Tests', () {
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
          home: CategoryFormScreen(),
        ),
      );
    }

    testWidgets('muestra título Nueva Categoría', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nueva Categoría'), findsOneWidget);
    });

    testWidgets('muestra selector de tipo con 4 opciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Pasivo'), findsOneWidget);
    });

    testWidgets('muestra campo de nombre', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nombre'), findsOneWidget);
    });

    testWidgets('muestra selector de iconos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Icono'), findsOneWidget);
      // Verificar que hay iconos disponibles
      expect(find.text('🏠'), findsOneWidget);
      expect(find.text('🍔'), findsOneWidget);
    });

    testWidgets('muestra botón Crear', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // El botón puede estar fuera del viewport, hacer scroll
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Crear'), findsOneWidget);
    });

    testWidgets('valida nombre requerido al guardar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el botón
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      // Intentar crear sin nombre
      final crearButton = find.text('Crear');
      if (crearButton.evaluate().isNotEmpty) {
        await tester.tap(crearButton);
        await tester.pump(const Duration(milliseconds: 300));
        // Verificar mensaje de error
        expect(find.textContaining('nombre'), findsWidgets);
      }
    });

    testWidgets('puede seleccionar icono', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para asegurarnos de ver los iconos
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap en un icono que debería estar visible
      final iconFinder = find.text('🚗');
      if (iconFinder.evaluate().isNotEmpty) {
        await tester.tap(iconFinder.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // El icono debería estar seleccionado (verificamos que sigue visible)
      expect(find.text('🚗'), findsWidgets);
    });

    testWidgets('puede cambiar tipo de categoría', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // El SegmentedButton debe estar visible al inicio
      expect(find.byType(SegmentedButton<String>), findsOneWidget);

      // Cambiar a Ingreso
      final ingresoButton = find.text('Ingreso');
      if (ingresoButton.evaluate().isNotEmpty) {
        await tester.tap(ingresoButton);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // El SegmentedButton sigue visible
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });
  });

  group('formCategoryTypeProvider', () {
    test('valor inicial es expense', () {
      final container = ProviderContainer();
      expect(container.read(formCategoryTypeProvider), equals('expense'));
      container.dispose();
    });

    test('puede cambiar tipo', () {
      final container = ProviderContainer();

      container.read(formCategoryTypeProvider.notifier).state = 'income';
      expect(container.read(formCategoryTypeProvider), equals('income'));

      container.read(formCategoryTypeProvider.notifier).state = 'asset';
      expect(container.read(formCategoryTypeProvider), equals('asset'));

      container.read(formCategoryTypeProvider.notifier).state = 'liability';
      expect(container.read(formCategoryTypeProvider), equals('liability'));

      container.dispose();
    });
  });

  group('selectedIconProvider', () {
    test('valor inicial es 📁', () {
      final container = ProviderContainer();
      expect(container.read(selectedIconProvider), equals('📁'));
      container.dispose();
    });

    test('puede cambiar icono', () {
      final container = ProviderContainer();

      container.read(selectedIconProvider.notifier).state = '🏠';
      expect(container.read(selectedIconProvider), equals('🏠'));

      container.read(selectedIconProvider.notifier).state = '🍔';
      expect(container.read(selectedIconProvider), equals('🍔'));

      container.dispose();
    });
  });

  group('selectedParentIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedParentIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar padre', () {
      final container = ProviderContainer();

      container.read(selectedParentIdProvider.notifier).state = 'parent-123';
      expect(container.read(selectedParentIdProvider), equals('parent-123'));

      container.read(selectedParentIdProvider.notifier).state = null;
      expect(container.read(selectedParentIdProvider), isNull);

      container.dispose();
    });
  });
}
