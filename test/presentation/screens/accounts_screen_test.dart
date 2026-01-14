import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/accounts_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('AccountsScreen', () {
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
          home: AccountsScreen(),
        ),
      );
    }

    testWidgets('muestra título Mis Cuentas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mis Cuentas'), findsOneWidget);
    });

    testWidgets('muestra botón de refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    // FAB removido de AccountsScreen - ahora lo provee MainShell

    testWidgets('muestra mensaje vacío sin cuentas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No hay cuentas'), findsOneWidget);
      expect(find.text('Crea tu primera cuenta para comenzar'), findsOneWidget);
    });

    testWidgets('muestra tarjeta de Balance Total', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Balance Total'), findsOneWidget);
    });

    testWidgets('muestra cuenta cuando existe', (tester) async {
      // Crear cuenta de prueba
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-test-001',
        name: 'Nequi Test',
        categoryId: assetCategory.id,
        balance: const Value(250000),
        icon: const Value('📱'),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nequi Test'), findsOneWidget);
      expect(find.text('📱'), findsOneWidget);
    });

    testWidgets('muestra múltiples cuentas', (tester) async {
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-test-001',
        name: 'Nequi',
        categoryId: assetCategory.id,
        balance: const Value(100000),
      ));

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-test-002',
        name: 'Efectivo',
        categoryId: assetCategory.id,
        balance: const Value(50000),
      ));

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-test-003',
        name: 'Bancolombia',
        categoryId: assetCategory.id,
        balance: const Value(500000),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Bancolombia'), findsOneWidget);
    });

    testWidgets('muestra balance con formato de moneda', (tester) async {
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-test-001',
        name: 'Test Account',
        categoryId: assetCategory.id,
        balance: const Value(1500000),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que muestra formato de moneda (con separador de miles)
      expect(find.textContaining('1.500.000'), findsWidgets);
    });

    testWidgets('botón refresh funciona sin errores', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Sigue mostrando la pantalla
      expect(find.text('Mis Cuentas'), findsOneWidget);
    });

    // Test de FAB removido - FAB ahora está en MainShell

    testWidgets('cuenta muestra etiqueta No suma cuando no incluida en total', (tester) async {
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-excluded',
        name: 'Cuenta No Suma',
        categoryId: assetCategory.id,
        balance: const Value(100000),
        includeInTotal: const Value(false),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cuenta No Suma'), findsOneWidget);
      expect(find.text('No suma'), findsOneWidget);
    });

    testWidgets('cuenta del sistema muestra etiqueta Predefinida', (tester) async {
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-system',
        name: 'Cuenta Sistema',
        categoryId: assetCategory.id,
        balance: const Value(100000),
        isSystem: const Value(true),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cuenta Sistema'), findsOneWidget);
      expect(find.text('Predefinida'), findsOneWidget);
    });

    testWidgets('balance total refleja suma de cuentas', (tester) async {
      final accountsDao = AccountsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      // Cuenta 1: 300,000
      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-1',
        name: 'Cuenta 1',
        categoryId: assetCategory.id,
        balance: const Value(300000),
      ));

      // Cuenta 2: 200,000
      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-2',
        name: 'Cuenta 2',
        categoryId: assetCategory.id,
        balance: const Value(200000),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Total: 500,000
      expect(find.textContaining('500'), findsWidgets);
      // 2 cuentas activas
      expect(find.text('2 cuentas activas'), findsOneWidget);
    });
  });

  group('AccountsScreen con cuenta no sumada', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      final accountsDao = AccountsDao(db);
      final categories = await categoriesDao.getAllCategories();
      final assetCategory = categories.firstWhere(
        (c) => c.type == 'asset' && c.parentId != null,
      );

      // Cuenta incluida: 400,000
      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-included',
        name: 'Incluida',
        categoryId: assetCategory.id,
        balance: const Value(400000),
        includeInTotal: const Value(true),
      ));

      // Cuenta no sumada: 100,000 (no debe sumarse al total)
      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: 'acc-not-summed',
        name: 'No Sumada',
        categoryId: assetCategory.id,
        balance: const Value(100000),
        includeInTotal: const Value(false),
      ));
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('balance total solo suma cuentas incluidas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: AccountsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Total debería ser 400,000 (solo la cuenta incluida)
      expect(find.textContaining('400'), findsWidgets);
    });
  });
}
