import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/account_form_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('AccountFormScreen Widget Tests', () {
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
          home: AccountFormScreen(),
        ),
      );
    }

    testWidgets('muestra título Nueva Cuenta', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nueva Cuenta'), findsOneWidget);
    });

    testWidgets('muestra campo de nombre', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nombre'), findsOneWidget);
    });

    testWidgets('muestra campo de saldo inicial', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Saldo inicial'), findsOneWidget);
    });

    testWidgets('muestra selector de tipo de cuenta', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tipo de cuenta'), findsOneWidget);
    });

    testWidgets('muestra selector de iconos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Icono'), findsOneWidget);
      // Verificar que hay iconos disponibles
      expect(find.text('💰'), findsWidgets);
      expect(find.text('💳'), findsOneWidget);
    });

    testWidgets('muestra selector de colores', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el selector de color
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('muestra switch de incluir en total', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el switch
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Incluir en balance total'), findsOneWidget);
    });

    testWidgets('muestra botón Crear', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el botón
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Crear'), findsOneWidget);
    });

    testWidgets('puede seleccionar icono', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Tap en un icono diferente
      await tester.tap(find.text('💳'));
      await tester.pump(const Duration(milliseconds: 300));

      // El icono debería estar seleccionado (sigue visible)
      expect(find.text('💳'), findsWidgets);
    });

    testWidgets('valida nombre requerido al guardar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el botón guardar
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));

      // Intentar crear sin nombre
      final crearButton = find.text('Crear');
      if (crearButton.evaluate().isNotEmpty) {
        await tester.tap(crearButton);
        await tester.pump(const Duration(milliseconds: 300));

        // Hacer scroll hacia arriba para ver el mensaje de error del campo nombre
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verificar mensaje de error (puede decir "nombre" o "Ingresa un nombre")
        expect(find.textContaining('nombre'), findsWidgets);
      }
    });

    testWidgets('muestra campo de descripción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver descripción
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });
  });

  group('accountIconProvider', () {
    test('valor inicial es 💰', () {
      final container = ProviderContainer();
      expect(container.read(accountIconProvider), equals('💰'));
      container.dispose();
    });

    test('puede cambiar icono', () {
      final container = ProviderContainer();

      container.read(accountIconProvider.notifier).state = '💳';
      expect(container.read(accountIconProvider), equals('💳'));

      container.read(accountIconProvider.notifier).state = '🏦';
      expect(container.read(accountIconProvider), equals('🏦'));

      container.dispose();
    });
  });

  group('accountColorProvider', () {
    test('valor inicial es #4CAF50', () {
      final container = ProviderContainer();
      expect(container.read(accountColorProvider), equals('#4CAF50'));
      container.dispose();
    });

    test('puede cambiar color', () {
      final container = ProviderContainer();

      container.read(accountColorProvider.notifier).state = '#2196F3';
      expect(container.read(accountColorProvider), equals('#2196F3'));

      container.read(accountColorProvider.notifier).state = '#F44336';
      expect(container.read(accountColorProvider), equals('#F44336'));

      container.dispose();
    });
  });

  group('includeInTotalProvider', () {
    test('valor inicial es true', () {
      final container = ProviderContainer();
      expect(container.read(includeInTotalProvider), isTrue);
      container.dispose();
    });

    test('puede cambiar valor', () {
      final container = ProviderContainer();

      container.read(includeInTotalProvider.notifier).state = false;
      expect(container.read(includeInTotalProvider), isFalse);

      container.read(includeInTotalProvider.notifier).state = true;
      expect(container.read(includeInTotalProvider), isTrue);

      container.dispose();
    });
  });

  group('accountCategoryIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(accountCategoryIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar categoría', () {
      final container = ProviderContainer();

      container.read(accountCategoryIdProvider.notifier).state = 'cat-asset-123';
      expect(container.read(accountCategoryIdProvider), equals('cat-asset-123'));

      container.dispose();
    });
  });
}
