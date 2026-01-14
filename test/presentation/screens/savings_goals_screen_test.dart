import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/presentation/screens/savings_goals_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/savings_goals_dao.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('SavingsGoalsScreen', () {
    late AppDatabase db;
    late SavingsGoalsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = SavingsGoalsDao(db);
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
          supportedLocales: [Locale('es', 'CO')],
          home: SavingsGoalsScreen(),
        ),
      );
    }

    Future<String> seedGoal({
      String name = 'Vacaciones',
      double targetAmount = 1000000,
      double currentAmount = 0,
      bool isActive = true,
      bool isCompleted = false,
    }) async {
      final id = const Uuid().v4();
      await dao.insertGoal(SavingsGoalsCompanion(
        id: Value(id),
        name: Value(name),
        targetAmount: Value(targetAmount),
        currentAmount: Value(currentAmount),
        isActive: Value(isActive),
        isCompleted: Value(isCompleted),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      return id;
    }

    testWidgets('muestra título Metas de Ahorro', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Metas de Ahorro'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay metas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('¡Empieza a ahorrar!'), findsOneWidget);
      expect(find.text('Crea tu primera meta de ahorro\ny alcanza tus sueños'), findsOneWidget);
    });

    testWidgets('muestra FAB Nueva Meta', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nueva Meta'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('muestra meta cuando existe', (tester) async {
      await seedGoal(name: 'iPhone 15', targetAmount: 5000000, currentAmount: 1000000);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('iPhone 15'), findsOneWidget);
      // Progreso: 1M de 5M = 20%
      expect(find.text('20%'), findsAtLeastNWidgets(1));
    });

    testWidgets('muestra múltiples metas', (tester) async {
      await seedGoal(name: 'Vacaciones', targetAmount: 3000000);
      await seedGoal(name: 'Carro', targetAmount: 20000000);
      await seedGoal(name: 'Fondo Emergencia', targetAmount: 5000000);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vacaciones'), findsOneWidget);
      expect(find.text('Carro'), findsOneWidget);
      expect(find.text('Fondo Emergencia'), findsOneWidget);
    });

    testWidgets('muestra resumen de metas', (tester) async {
      await seedGoal(
        name: 'Meta 1',
        targetAmount: 1000000,
        currentAmount: 500000,
      );
      await seedGoal(
        name: 'Meta 2',
        targetAmount: 2000000,
        currentAmount: 1000000,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Progreso Total'), findsOneWidget);
      // 1.5M de 3M = 50%
      expect(find.text('50%'), findsAtLeastNWidgets(1));
      expect(find.text('2 metas'), findsOneWidget);
    });

    testWidgets('muestra sección En Progreso', (tester) async {
      await seedGoal(name: 'En Progreso', isActive: true, isCompleted: false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('En Progreso'), findsAtLeastNWidgets(1));
    });

    testWidgets('abre formulario al tocar FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Meta de Ahorro'), findsOneWidget);
      expect(find.text('Nombre de la meta'), findsOneWidget);
      expect(find.text('Monto objetivo'), findsOneWidget);
    });

    testWidgets('formulario tiene selector de color', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('formulario tiene selector de icono', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Icono'), findsOneWidget);
    });

    testWidgets('muestra detalle al tocar meta', (tester) async {
      await seedGoal(
        name: 'Vacaciones',
        targetAmount: 3000000,
        currentAmount: 1500000,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vacaciones'));
      await tester.pumpAndSettle();

      // Verificar que se muestra el detalle
      expect(find.text('Meta'), findsOneWidget);
      expect(find.text('Ahorrado'), findsOneWidget);
      expect(find.text('Faltante'), findsOneWidget);
    });

    testWidgets('detalle muestra botón Agregar Contribución', (tester) async {
      await seedGoal(name: 'Test Meta');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Contribución'), findsOneWidget);
    });

    testWidgets('detalle muestra botones Editar y Pausar', (tester) async {
      await seedGoal(name: 'Test Meta');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Pausar'), findsOneWidget);
    });

    testWidgets('detalle muestra botón Eliminar', (tester) async {
      await seedGoal(name: 'Test Meta');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('muestra progreso circular en detalle', (tester) async {
      await seedGoal(
        name: 'Test Meta',
        targetAmount: 1000000,
        currentAmount: 750000,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Meta'));
      await tester.pumpAndSettle();

      // Debería mostrar 75%
      expect(find.text('75%'), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SavingsGoalFormSheet', () {
    late AppDatabase db;

    setUp(() async {
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
          supportedLocales: [Locale('es', 'CO')],
          home: SavingsGoalsScreen(),
        ),
      );
    }

    testWidgets('formulario tiene campos requeridos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Meta'));
      await tester.pumpAndSettle();

      // Verificar campos del formulario
      expect(find.text('Nombre de la meta'), findsOneWidget);
      expect(find.text('Monto objetivo'), findsOneWidget);
      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets('formulario muestra botón crear', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Meta'));
      await tester.pumpAndSettle();

      // Hacer scroll para ver el botón
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crear Meta'), findsOneWidget);
    });
  });
}
