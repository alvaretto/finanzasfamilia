import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/main_shell.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });
  group('MainShell', () {
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
          home: MainShell(),
        ),
      );
    }

    testWidgets('muestra NavigationBar con 4 destinos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('muestra etiquetas de navegación', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que las etiquetas existen (pueden aparecer múltiples veces)
      expect(find.text('¿Cómo Voy?'), findsWidgets);
      expect(find.text('Movimientos'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Presupuestos'), findsOneWidget);
    });

    testWidgets('muestra FAB para nueva transacción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
    });

    testWidgets('cambia de tab al tocar destino', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Inicialmente muestra Dashboard (¿Cómo Voy?)
      expect(find.text('¿Cómo Voy?'), findsWidgets);

      // Tocar en Movimientos
      await tester.tap(find.text('Movimientos'));
      await tester.pump(const Duration(milliseconds: 500));

      // Debería mostrar pantalla de movimientos
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('abre sheet de acciones rápidas al tocar FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Tocar FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Iniciar animación
      await tester.pump(const Duration(milliseconds: 500)); // Esperar animación

      // Debería mostrar el título del sheet
      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
    });
  });

  group('currentTabProvider', () {
    test('valor inicial es 0', () {
      final container = ProviderContainer();
      expect(container.read(currentTabProvider), equals(0));
      container.dispose();
    });

    test('puede cambiar de tab', () {
      final container = ProviderContainer();

      container.read(currentTabProvider.notifier).state = 2;
      expect(container.read(currentTabProvider), equals(2));

      container.read(currentTabProvider.notifier).state = 1;
      expect(container.read(currentTabProvider), equals(1));

      container.dispose();
    });
  });
}
