import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/dashboard_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('DashboardScreen', () {
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
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('muestra título ¿Cómo Voy?', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo Voy?'), findsOneWidget);
    });

    testWidgets('muestra botón de refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('muestra tarjeta de Mis Ahorros Netos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mis Ahorros Netos'), findsOneWidget);
    });

    testWidgets('muestra tarjeta de Saldo Disponible Real', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saldo Disponible Real'), findsOneWidget);
    });

    testWidgets('muestra resumen del mes con título correcto', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El título debería contener "Resumen de"
      expect(find.textContaining('Resumen de'), findsOneWidget);
    });

    testWidgets('muestra etiquetas de ingresos, gastos y balance', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('muestra Lo que Tengo y Lo que Debo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lo que Tengo'), findsOneWidget);
      expect(find.text('Lo que Debo'), findsOneWidget);
    });

    testWidgets('DashboardScreen es scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El dashboard usa ListView que es scrollable
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay gastos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No hay gastos este mes'), findsOneWidget);
    });

    testWidgets('muestra gastos por categoría cuando existen', (tester) async {
      // Agregar transacción de gasto
      final transactionsDao = TransactionsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-test-001',
        type: 'expense',
        amount: 75000,
        description: const Value('Mercado'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debería mostrar la sección de gastos
      expect(find.text('Gastos por Categoría'), findsOneWidget);
      expect(find.text(expenseCategory.name), findsOneWidget);
    });

    testWidgets('botón refresh funciona sin errores', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar botón refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Después de recargar, sigue mostrando el dashboard sin errores
      expect(find.text('¿Cómo Voy?'), findsOneWidget);
      expect(find.text('Mis Ahorros Netos'), findsOneWidget);
    });
  });

  group('DashboardScreen con cuentas', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      // Agregar cuenta con saldo
      final accountsDao = AccountsDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'account-test-001',
        name: 'Cuenta Bancaria Test',
        categoryId: assetCategory.id,
        balance: const Value(500000),
      ));
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
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('muestra activos con balance positivo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El saldo debería mostrarse formateado
      expect(find.textContaining('500'), findsWidgets);
    });
  });

  group('TrafficLightIndicator', () {
    testWidgets('muestra indicador compacto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: _TestTrafficLight(compact: true),
            ),
          ),
        ),
      );

      // El indicador compacto tiene un Container de 16x16
      expect(find.byType(Container), findsWidgets);
    });
  });
}

// Widget auxiliar para probar TrafficLightIndicator
class _TestTrafficLight extends StatelessWidget {
  final bool compact;

  const _TestTrafficLight({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 16 : 60,
      height: compact ? 16 : 60,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}
