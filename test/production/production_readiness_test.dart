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
        categoryId: 'cat-1',
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
        categoryId: 'cat-1',
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

  // ============================================
  // TESTS AGRESIVOS DE PRODUCCIÓN V2
  // ============================================

  group('Production Aggressive - Extreme Values', () {
    test('AccountModel soporta balances astronomicos sin overflow', () {
      // Riqueza de un millonario
      final millionaire = AccountModel.create(
        userId: 'test', name: 'Fortuna',
        type: AccountType.investment, currency: 'USD',
        balance: 1000000000000.00, // 1 trillon
      );
      expect(millionaire.balance, 1000000000000.00);
      expect(millionaire.type.isAsset, true);

      // Deuda masiva
      final massiveDebt = AccountModel.create(
        userId: 'test', name: 'Deuda Nacional',
        type: AccountType.loan, currency: 'MXN',
        balance: -9999999999999.99,
      );
      expect(massiveDebt.balance, -9999999999999.99);
      expect(massiveDebt.type.isLiability, true);
    });

    test('TransactionModel maneja montos minimos (centavos)', () {
      final centavo = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 0.01, type: TransactionType.expense,
      );
      expect(centavo.amount, 0.01);
      expect(centavo.signedAmount, -0.01);
    });

    test('BudgetModel con presupuesto de centavos', () {
      final microBudget = BudgetModel(
        id: '1', userId: 'test', categoryId: 'cat-1',
        amount: 0.01, period: BudgetPeriod.weekly,
        startDate: DateTime.now(), spent: 0.005,
      );
      expect(microBudget.percentSpent, closeTo(50, 1));
    });

    test('GoalModel con meta de un centavo', () {
      final microGoal = GoalModel.create(
        userId: 'test', name: 'Micro Meta',
        targetAmount: 0.01, currentAmount: 0.01,
      );
      expect(microGoal.isCompleted, true);
      expect(microGoal.percentComplete, 100);
    });
  });

  group('Production Aggressive - String Edge Cases', () {
    test('Strings vacios no causan crash', () {
      final account = AccountModel.create(
        userId: '', name: '', type: AccountType.bank, currency: '',
      );
      expect(account.userId, '');
      expect(account.name, '');
    });

    test('Strings muy largos son manejados', () {
      final longString = 'A' * 10000; // 10,000 caracteres
      final tx = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 100, type: TransactionType.expense,
        description: longString,
        notes: longString,
      );
      expect(tx.description!.length, 10000);
      expect(tx.notes!.length, 10000);
    });

    test('Caracteres unicode especiales son preservados', () {
      final unicodeTx = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 100, type: TransactionType.expense,
        description: '中文 العربية 日本語 한국어 🇲🇽🇺🇸🇪🇺',
        notes: '∑∏∫∂√∞≠≈',
      );
      expect(unicodeTx.description, contains('中文'));
      expect(unicodeTx.notes, contains('∑'));
    });

    test('Newlines y tabs en strings', () {
      final multiline = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 100, type: TransactionType.expense,
        description: 'Linea 1\nLinea 2\tTabulado',
        notes: '\n\n\t\t',
      );
      expect(multiline.description, contains('\n'));
      expect(multiline.notes, contains('\t'));
    });
  });

  group('Production Aggressive - Date Edge Cases', () {
    test('Transaccion en fecha muy antigua', () {
      final ancient = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 100, type: TransactionType.expense,
        date: DateTime(1900, 1, 1),
      );
      expect(ancient.date.year, 1900);
    });

    test('Transaccion en fecha futura lejana', () {
      final future = TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 100, type: TransactionType.expense,
        date: DateTime(2099, 12, 31, 23, 59, 59),
      );
      expect(future.date.year, 2099);
    });

    test('Meta con fecha limite pasada', () {
      final pastGoal = GoalModel.create(
        userId: 'test', name: 'Meta Pasada',
        targetAmount: 1000, currentAmount: 500,
        targetDate: DateTime(2020, 1, 1),
      );
      expect(pastGoal.targetDate!.isBefore(DateTime.now()), true);
      expect(pastGoal.isCompleted, false);
    });

    test('Presupuesto en año bisiesto febrero 29', () {
      final leapYear = BudgetModel.create(
        userId: 'test', categoryId: 'cat-1',
        amount: 1000, period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 2, 29), // 2024 es bisiesto
      );
      expect(leapYear.startDate.day, 29);
      expect(leapYear.startDate.month, 2);
    });
  });

  group('Production Aggressive - Stress Tests', () {
    test('Crear 10,000 transacciones', () {
      final stopwatch = Stopwatch()..start();
      final transactions = List.generate(10000, (i) => TransactionModel.create(
        userId: 'stress-test',
        accountId: 'acc-${i % 100}',
        amount: (i % 1000) * 1.5 + 0.01,
        type: TransactionType.values[i % 3],
        description: 'Stress test transaction $i',
        categoryId: 'cat-${i % 20}',
      ));
      stopwatch.stop();

      expect(transactions.length, 10000);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // < 5 segundos
    });

    test('Filtrar 10,000 transacciones con filtros complejos', () {
      final transactions = List.generate(10000, (i) => TransactionModel.create(
        userId: 'stress-test',
        accountId: 'acc-${i % 10}',
        amount: i.toDouble(),
        type: TransactionType.values[i % 3],
        description: 'Transaction $i with keyword-${i % 50}',
      ));

      const filters = TransactionFilters(
        searchQuery: 'keyword-25',
        type: TransactionType.expense,
        minAmount: 1000,
        maxAmount: 9000,
      );

      final stopwatch = Stopwatch()..start();
      final result = filters.apply(transactions);
      stopwatch.stop();

      expect(result.isNotEmpty, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // < 500ms
    });

    test('Calcular patrimonio con 1000 cuentas', () {
      final accounts = List.generate(1000, (i) => AccountModel.create(
        userId: 'stress',
        name: 'Account $i',
        type: AccountType.values[i % AccountType.values.length],
        currency: 'MXN',
        balance: (i % 2 == 0 ? 1 : -1) * i * 100.0,
      ));

      final stopwatch = Stopwatch()..start();
      final assets = accounts.where((a) => a.type.isAsset).fold(0.0, (sum, a) => sum + a.balance);
      final liabilities = accounts.where((a) => a.type.isLiability).fold(0.0, (sum, a) => sum + a.balance.abs());
      stopwatch.stop();

      expect(assets, isNotNull);
      expect(liabilities, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // < 100ms
    });
  });

  group('Production Aggressive - Division by Zero Prevention', () {
    test('BudgetModel con amount 0 y spent > 0', () {
      final zeroBudget = BudgetModel(
        id: '1', userId: 'test', categoryId: 'cat-1',
        amount: 0, period: BudgetPeriod.monthly,
        startDate: DateTime.now(), spent: 100,
      );
      expect(zeroBudget.percentSpent, 0); // No debe ser infinito
      expect(zeroBudget.remaining, -100);
      expect(zeroBudget.isOverBudget, true); // spent > amount
    });

    test('GoalModel con targetAmount 0 y currentAmount > 0', () {
      final zeroTarget = GoalModel.create(
        userId: 'test', name: 'Zero Target',
        targetAmount: 0, currentAmount: 1000,
      );
      expect(zeroTarget.percentComplete, 0); // No debe ser infinito (division por cero protegida)
      expect(zeroTarget.isCompleted, true); // currentAmount >= targetAmount (1000 >= 0)
    });

    test('AccountModel credit con creditLimit 0', () {
      const zeroCreditLimit = AccountModel(
        id: '1', userId: 'test', name: 'Zero Credit',
        type: AccountType.credit, currency: 'MXN',
        balance: -1000, creditLimit: 0,
      );
      expect(zeroCreditLimit.availableBalance, -1000);
    });
  });

  group('Production Aggressive - Concurrent Modifications', () {
    test('Copiar y modificar modelos no afecta originales', () {
      final original = AccountModel.create(
        userId: 'test', name: 'Original',
        type: AccountType.bank, currency: 'MXN', balance: 1000,
      );

      final copy = AccountModel(
        id: original.id, userId: original.userId,
        name: 'Modified', type: original.type,
        currency: original.currency, balance: 2000,
      );

      expect(original.name, 'Original');
      expect(original.balance, 1000);
      expect(copy.name, 'Modified');
      expect(copy.balance, 2000);
    });

    test('Lista de transacciones es inmutable despues de filtrar', () {
      final transactions = List.generate(100, (i) => TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: i.toDouble(), type: TransactionType.expense,
      ));

      const filters = TransactionFilters(minAmount: 50);
      final filtered = filters.apply(transactions);

      expect(filtered.length, lessThan(transactions.length));
      expect(transactions.length, 100); // Original no modificado
    });
  });

  group('Production Aggressive - All AccountType scenarios', () {
    test('Todos los tipos de cuenta clasifican correctamente', () {
      // Activos
      expect(AccountType.bank.isAsset, true);
      expect(AccountType.cash.isAsset, true);
      expect(AccountType.savings.isAsset, true);
      expect(AccountType.investment.isAsset, true);

      // Pasivos
      expect(AccountType.credit.isLiability, true);
      expect(AccountType.loan.isLiability, true);
      expect(AccountType.payable.isLiability, true);

      // Caso especial: receivable es dinero que nos deben, es un ACTIVO
      expect(AccountType.receivable.isAsset, true);
      expect(AccountType.receivable.isLiability, false);
    });

    test('availableBalance correcto para cada tipo', () {
      // Cuenta normal - availableBalance = balance
      const bank = AccountModel(
        id: '1', userId: 'test', name: 'Bank',
        type: AccountType.bank, currency: 'MXN', balance: 5000,
      );
      expect(bank.availableBalance, 5000);

      // Credito - availableBalance = creditLimit + balance (balance es negativo)
      const credit = AccountModel(
        id: '2', userId: 'test', name: 'Credit',
        type: AccountType.credit, currency: 'MXN',
        balance: -3000, creditLimit: 10000,
      );
      expect(credit.availableBalance, 7000);

      // Credito sin limite - availableBalance = balance
      const creditNoLimit = AccountModel(
        id: '3', userId: 'test', name: 'Credit No Limit',
        type: AccountType.credit, currency: 'MXN', balance: -1000,
      );
      expect(creditNoLimit.availableBalance, -1000);
    });
  });

  group('Production Aggressive - Financial Calculations Precision', () {
    test('Suma de transacciones mantiene precision decimal', () {
      final transactions = List.generate(1000, (i) => TransactionModel.create(
        userId: 'test', accountId: 'acc',
        amount: 0.01, type: TransactionType.income,
      ));

      final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
      expect(total, closeTo(10.0, 0.01)); // 1000 * 0.01 = 10.00
    });

    test('Calculo de porcentaje es preciso', () {
      final budget = BudgetModel(
        id: '1', userId: 'test', categoryId: 'cat-1',
        amount: 333.33, period: BudgetPeriod.monthly,
        startDate: DateTime.now(), spent: 111.11,
      );
      expect(budget.percentSpent, closeTo(33.33, 0.1));
    });
  });
}
