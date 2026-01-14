import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/entities/transaction.dart';
import 'package:finanzas_familiares/domain/entities/account.dart';
import 'package:finanzas_familiares/domain/entities/category.dart';
import 'package:finanzas_familiares/domain/entities/budget.dart';
import 'package:finanzas_familiares/domain/entities/savings_goal.dart';

/// Contract Tests para serialización JSON de modelos de dominio.
///
/// Estos tests verifican que:
/// 1. toJson() → fromJson() preserva todos los datos (roundtrip)
/// 2. Los tipos de datos se serializan correctamente
/// 3. Los valores opcionales se manejan correctamente
///
/// CRÍTICO: Si algún test falla, la sincronización con PowerSync puede fallar.
void main() {
  group('Contract: Transaction serialization', () {
    test('roundtrip preserves all fields', () {
      final original = Transaction(
        id: 'tx-001',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.expense,
        amount: 150000.50,
        date: DateTime(2026, 1, 10, 14, 30),
        description: 'Mercado semanal',
        notes: 'Incluye frutas y verduras',
        transferToAccountId: null,
        isRecurring: false,
        recurringId: null,
        isPending: false,
        createdAt: DateTime(2026, 1, 10, 14, 30),
        updatedAt: DateTime(2026, 1, 10, 14, 30),
      );

      final json = original.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.id, equals(original.id));
      expect(recovered.amount, equals(original.amount));
      expect(recovered.type, equals(original.type));
      expect(recovered.description, equals(original.description));
    });

    test('roundtrip with null optional fields', () {
      final original = Transaction(
        id: 'tx-002',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.income,
        amount: 5000000.0,
        date: DateTime(2026, 1, 15),
        description: null,
        notes: null,
        transferToAccountId: null,
        isRecurring: false,
        recurringId: null,
        isPending: false,
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );

      final json = original.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.description, isNull);
      expect(recovered.notes, isNull);
    });

    test('roundtrip for transfer transaction', () {
      final original = Transaction(
        id: 'tx-003',
        accountId: 'acc-001',
        categoryId: 'cat-transfer',
        type: TransactionType.transfer,
        amount: 200000.0,
        date: DateTime(2026, 1, 10),
        transferToAccountId: 'acc-002',
        isRecurring: false,
        isPending: false,
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = original.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.transferToAccountId, equals('acc-002'));
      expect(recovered.isTransfer, isTrue);
    });

    test('enum TransactionType serializes correctly', () {
      for (final type in TransactionType.values) {
        final tx = Transaction(
          id: 'tx-enum-$type',
          accountId: 'acc-001',
          categoryId: 'cat-001',
          type: type,
          amount: 100.0,
          date: DateTime(2026, 1, 10),
          createdAt: DateTime(2026, 1, 10),
          updatedAt: DateTime(2026, 1, 10),
        );

        final json = tx.toJson();
        final recovered = Transaction.fromJson(json);

        expect(recovered.type, equals(type));
      }
    });
  });

  group('Contract: Account serialization', () {
    test('roundtrip preserves all fields', () {
      final original = Account(
        id: 'acc-001',
        name: 'Bancolombia Ahorros',
        categoryId: 'cat-banks',
        balance: 2500000.75,
        currency: 'COP',
        institution: 'Bancolombia',
        accountNumber: '****1234',
        notes: 'Cuenta principal',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = original.toJson();
      final recovered = Account.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.balance, equals(original.balance));
      expect(recovered.institution, equals(original.institution));
    });

    test('roundtrip with minimal fields', () {
      final original = Account(
        id: 'acc-002',
        name: 'Efectivo',
        categoryId: 'cat-cash',
        balance: 50000.0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final recovered = Account.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.currency, isNull);
      expect(recovered.institution, isNull);
    });

    test('negative balance serializes correctly', () {
      final original = Account(
        id: 'acc-003',
        name: 'Tarjeta Visa',
        categoryId: 'cat-credit',
        balance: -1500000.0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final recovered = Account.fromJson(json);

      expect(recovered.balance, equals(-1500000.0));
      expect(recovered.hasNegativeBalance, isTrue);
    });
  });

  group('Contract: Category serialization', () {
    test('roundtrip preserves all fields', () {
      final original = Category(
        id: 'cat-001',
        name: 'Alimentación',
        icon: 'restaurant',
        type: CategoryType.expense,
        parentId: 'cat-gastos',
        level: 1,
        sortOrder: 1,
        isActive: true,
        isSystem: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final recovered = Category.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.parentId, equals(original.parentId));
      expect(recovered.level, equals(original.level));
    });

    test('enum CategoryType serializes correctly', () {
      for (final type in CategoryType.values) {
        final cat = Category(
          id: 'cat-$type',
          name: 'Test $type',
          type: type,
          level: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        final json = cat.toJson();
        final recovered = Category.fromJson(json);

        expect(recovered.type, equals(type));
      }
    });

    test('root category (no parent) serializes correctly', () {
      final original = Category(
        id: 'cat-root',
        name: 'Activos',
        type: CategoryType.asset,
        parentId: null,
        level: 0,
        isSystem: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final recovered = Category.fromJson(json);

      expect(recovered.parentId, isNull);
      expect(recovered.isRoot, isTrue);
      expect(recovered.isSystem, isTrue);
    });
  });

  group('Contract: Budget serialization', () {
    test('roundtrip preserves all fields', () {
      final original = Budget(
        id: 'budget-001',
        categoryId: 'cat-food',
        amount: 800000.0,
        month: 1,
        year: 2026,
        notes: 'Presupuesto de alimentación',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = original.toJson();
      final recovered = Budget.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.amount, equals(original.amount));
      expect(recovered.notes, equals(original.notes));
    });

    test('budget with null notes serializes correctly', () {
      final original = Budget(
        id: 'budget-002',
        categoryId: 'cat-transport',
        amount: 200000.0,
        month: 2,
        year: 2026,
        notes: null,
        isActive: true,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final json = original.toJson();
      final recovered = Budget.fromJson(json);

      expect(recovered.notes, isNull);
      expect(recovered.amount, equals(200000.0));
    });

    test('inactive budget serializes correctly', () {
      final original = Budget(
        id: 'budget-003',
        categoryId: 'cat-food',
        amount: 500000.0,
        month: 1,
        year: 2026,
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 31),
      );

      final json = original.toJson();
      final recovered = Budget.fromJson(json);

      expect(recovered.isActive, isFalse);
      expect(recovered.periodName, equals('Enero 2026'));
    });
  });

  group('Contract: SavingsGoal serialization', () {
    test('roundtrip preserves all fields', () {
      final original = SavingsGoal(
        id: 'goal-001',
        name: 'Vacaciones 2026',
        description: 'Viaje a Cartagena',
        targetAmount: 5000000.0,
        currentAmount: 1500000.0,
        targetDate: DateTime(2026, 12, 15),
        accountId: 'acc-savings',
        color: 0xFFFF5722, // Deep Orange
        icon: 0xe048, // beach_access icon
        isActive: true,
        isCompleted: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
        completedAt: null,
      );

      final json = original.toJson();
      final recovered = SavingsGoal.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.targetAmount, equals(original.targetAmount));
      expect(recovered.currentAmount, equals(original.currentAmount));
    });

    test('completed goal with completedAt serializes correctly', () {
      final original = SavingsGoal(
        id: 'goal-002',
        name: 'Fondo de emergencia',
        targetAmount: 10000000.0,
        currentAmount: 10000000.0,
        targetDate: DateTime(2026, 6, 1),
        isActive: false,
        isCompleted: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2026, 1, 5),
        completedAt: DateTime(2026, 1, 5),
      );

      final json = original.toJson();
      final recovered = SavingsGoal.fromJson(json);

      expect(recovered.isCompleted, isTrue);
      expect(recovered.completedAt, isNotNull);
      expect(recovered.completedAt, equals(original.completedAt));
    });

    test('goal with default color and icon serializes correctly', () {
      final original = SavingsGoal(
        id: 'goal-003',
        name: 'Meta simple',
        targetAmount: 1000000.0,
        currentAmount: 0.0,
        targetDate: DateTime(2026, 12, 31),
        description: null,
        accountId: null,
        // Uses default color 0xFF4CAF50 and icon 0xe57f
        isActive: true,
        isCompleted: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        completedAt: null,
      );

      final json = original.toJson();
      final recovered = SavingsGoal.fromJson(json);

      expect(recovered, equals(original));
      expect(recovered.description, isNull);
      expect(recovered.accountId, isNull);
      expect(recovered.color, equals(0xFF4CAF50)); // Default green
    });
  });

  group('Contract: Edge cases', () {
    test('very large amounts serialize correctly', () {
      final tx = Transaction(
        id: 'tx-large',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.income,
        amount: 999999999999.99,
        date: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = tx.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered.amount, equals(999999999999.99));
    });

    test('very small amounts serialize correctly', () {
      final tx = Transaction(
        id: 'tx-small',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.expense,
        amount: 0.01,
        date: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = tx.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered.amount, equals(0.01));
    });

    test('special characters in strings serialize correctly', () {
      final tx = Transaction(
        id: 'tx-special',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.expense,
        amount: 50000.0,
        date: DateTime(2026, 1, 10),
        description: 'Compra en "Tienda D\'María" & Hermanos',
        notes: 'Incluye: pan, leche, huevos\n\tTotal: \$50.000',
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = tx.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered.description, equals(tx.description));
      expect(recovered.notes, equals(tx.notes));
    });

    test('dates at boundaries serialize correctly', () {
      final tx = Transaction(
        id: 'tx-boundary',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.expense,
        amount: 100.0,
        date: DateTime(2026, 12, 31, 23, 59, 59),
        createdAt: DateTime(2026, 1, 1, 0, 0, 0),
        updatedAt: DateTime(2026, 12, 31, 23, 59, 59),
      );

      final json = tx.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered.date, equals(tx.date));
      expect(recovered.createdAt, equals(tx.createdAt));
    });

    test('empty strings serialize correctly', () {
      final tx = Transaction(
        id: 'tx-empty',
        accountId: 'acc-001',
        categoryId: 'cat-001',
        type: TransactionType.expense,
        amount: 100.0,
        date: DateTime(2026, 1, 10),
        description: '',
        notes: '',
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final json = tx.toJson();
      final recovered = Transaction.fromJson(json);

      expect(recovered.description, equals(''));
      expect(recovered.notes, equals(''));
    });
  });
}
