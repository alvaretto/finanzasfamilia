// Tests agresivos de produccion
// Verifican que la app esta lista para deployment

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart';
import 'package:finanzas_familiares/features/goals/domain/models/goal_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/search_filter_sheet.dart';

void main() {
  group('Production Readiness - Models', () {
    test('AccountModel maneja valores extremos', () {
      // Test con balance muy grande
      final largeBalance = AccountModel.create(
        userId: 'test',
        name: 'Large',
        type: AccountType.bank,
        currency: 'MXN',
        balance: 999999999999.99,
      );
      expect(largeBalance.balance, 999999999999.99);

      // Test con balance negativo extremo
      final negativeBalance = AccountModel.create(
        userId: 'test',
        name: 'Negative',
        type: AccountType.credit,
        currency: 'MXN',
        balance: -999999999999.99,
      );
      expect(negativeBalance.balance, -999999999999.99);

      // Test con balance cero
      final zeroBalance = AccountModel.create(
        userId: 'test',
        name: 'Zero',
        type: AccountType.cash,
        currency: 'MXN',
        balance: 0,
      );
      expect(zeroBalance.balance, 0);
    });

    test('TransactionModel maneja strings con caracteres especiales', () {
      final tx = TransactionModel.create(
        userId: 'test',
        accountId: 'acc-1',
        amount: 100,
        type: TransactionType.expense,
        description: 'Test <script>alert("xss")</script> & special chars: "quotes" \'apostrophe\'',
        notes: 'Notas con emojis 💰🎉 y acentos: áéíóú ñ',
      );
      expect(tx.description, contains('<script>'));
      expect(tx.notes, contains('💰'));
    });

    test('BudgetModel previene division por cero', () {
      final budget = BudgetModel.create(
        userId: 'test',
        categoryId: 1,
        amount: 0,
        period: BudgetPeriod.monthly,
      );
      expect(budget.percentSpent, 0);
      expect(budget.remaining, 0);
    });

    test('GoalModel calcula progreso correctamente en edge cases', () {
      // Meta con 0 target - debe retornar 0 para evitar division por cero
      final zeroGoal = GoalModel.create(
        userId: 'test',
        name: 'Zero Goal',
        targetAmount: 0,
        currentAmount: 100,
      );
      expect(zeroGoal.percentComplete, 0); // Correcto: evita division por cero

      // Meta con valores iguales
      final completeGoal = GoalModel.create(
        userId: 'test',
        name: 'Complete',
        targetAmount: 1000,
        currentAmount: 1000,
      );
      expect(completeGoal.percentComplete, 100);
      expect(completeGoal.isCompleted, true);

      // Meta sobrepasada
      final overGoal = GoalModel.create(
        userId: 'test',
        name: 'Over',
        targetAmount: 1000,
        currentAmount: 1500,
      );
      expect(overGoal.isCompleted, true);
    });

    test('AccountType cubre todos los casos', () {
      for (final type in AccountType.values) {
        expect(type.displayName.isNotEmpty, true);
        expect(type.icon.isNotEmpty, true);
        // isLiability o isAsset debe tener sentido
        expect(type.isLiability || type.isAsset || type == AccountType.receivable, true);
      }
    });

    test('TransactionType cubre todos los casos', () {
      for (final type in TransactionType.values) {
        expect(type.displayName.isNotEmpty, true);
        expect(type.icon.isNotEmpty, true);
      }
    });

    test('BudgetPeriod cubre todos los casos', () {
      for (final period in BudgetPeriod.values) {
        expect(period.displayName.isNotEmpty, true);
        expect(period.shortName.isNotEmpty, true);
      }
    });
  });

  group('Production Readiness - Filters', () {
    test('TransactionFilters maneja lista vacia', () {
      const filters = TransactionFilters();
      final result = filters.apply([]);
      expect(result, isEmpty);
    });

    test('TransactionFilters con todos los filtros activos', () {
      const filters = TransactionFilters(
        searchQuery: 'test',
        type: TransactionType.expense,
        accountId: 'acc-1',
        categoryId: 1,
        minAmount: 10,
        maxAmount: 100,
      );
      expect(filters.hasActiveFilters, true);
      expect(filters.activeFilterCount, 5);
    });

    test('TransactionFilters copyWith funciona correctamente', () {
      const original = TransactionFilters(searchQuery: 'test');
      final cleared = original.copyWith(clearSearch: true);
      expect(cleared.searchQuery, isNull);
      expect(cleared.hasActiveFilters, false);
    });
  });

  group('Production Readiness - Memory Safety', () {
    test('Crear muchos modelos no causa problemas', () {
      final accounts = List.generate(1000, (i) => AccountModel.create(
        userId: 'test',
        name: 'Account $i',
        type: AccountType.bank,
        currency: 'MXN',
        balance: i * 100.0,
      ));
      expect(accounts.length, 1000);

      final transactions = List.generate(1000, (i) => TransactionModel.create(
        userId: 'test',
        accountId: 'acc-$i',
        amount: i * 10.0,
        type: i % 2 == 0 ? TransactionType.income : TransactionType.expense,
      ));
      expect(transactions.length, 1000);
    });

    test('Filtrar listas grandes es eficiente', () {
      final transactions = List.generate(10000, (i) => TransactionModel.create(
        userId: 'test',
        accountId: 'acc-${i % 10}',
        amount: i * 1.5,
        type: i % 3 == 0 ? TransactionType.income : TransactionType.expense,
        description: 'Transaction $i description',
      ));

      const filters = TransactionFilters(
        type: TransactionType.income,
        minAmount: 1000,
      );

      final stopwatch = Stopwatch()..start();
      final result = filters.apply(transactions);
      stopwatch.stop();

      expect(result.isNotEmpty, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Debe ser menor a 1 segundo
    });
  });

  group('Production Readiness - Null Safety', () {
    test('AccountModel maneja campos nullable correctamente', () {
      final account = AccountModel.create(
        userId: 'test',
        name: 'Test',
        type: AccountType.bank,
        currency: 'MXN',
      );
      expect(account.bankName, isNull);
      expect(account.lastFourDigits, isNull);
      expect(account.familyId, isNull);
      // color e icon tienen valores por defecto (basados en tipo de cuenta)
      expect(account.color, isNotNull);
      expect(account.icon, isNotNull);
    });

    test('TransactionModel maneja campos nullable correctamente', () {
      final tx = TransactionModel.create(
        userId: 'test',
        accountId: 'acc-1',
        amount: 100,
        type: TransactionType.expense,
      );
      expect(tx.description, isNull);
      expect(tx.notes, isNull);
      expect(tx.categoryId, isNull);
      expect(tx.categoryName, isNull);
      expect(tx.categoryIcon, isNull);
      expect(tx.transferToAccountId, isNull);
    });
  });

  group('Production Readiness - Calculations', () {
    test('Calculo de patrimonio neto es correcto', () {
      final accounts = [
        const AccountModel(
          id: '1', userId: 'test', name: 'Bank',
          type: AccountType.bank, currency: 'MXN', balance: 10000,
        ),
        const AccountModel(
          id: '2', userId: 'test', name: 'Cash',
          type: AccountType.cash, currency: 'MXN', balance: 5000,
        ),
        const AccountModel(
          id: '3', userId: 'test', name: 'Credit',
          type: AccountType.credit, currency: 'MXN', balance: -3000,
        ),
        const AccountModel(
          id: '4', userId: 'test', name: 'Loan',
          type: AccountType.loan, currency: 'MXN', balance: -50000,
        ),
      ];

      final assets = accounts.where((a) => a.type.isAsset).fold(0.0, (sum, a) => sum + a.balance);
      final liabilities = accounts.where((a) => a.type.isLiability).fold(0.0, (sum, a) => sum + a.balance.abs());
      final netWorth = assets - liabilities;

      expect(assets, 15000);
      expect(liabilities, 53000);
      expect(netWorth, -38000);
    });

    test('Calculo de balance de credito disponible es correcto', () {
      const creditCard = AccountModel(
        id: '1', userId: 'test', name: 'Visa',
        type: AccountType.credit, currency: 'MXN',
        balance: -5000, creditLimit: 20000,
      );
      expect(creditCard.availableBalance, 15000);
    });
  });
}
