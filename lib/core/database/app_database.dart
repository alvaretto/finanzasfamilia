import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ============================================================================
// TABLES
// ============================================================================

/// Cuentas financieras (banco, efectivo, tarjeta, etc.)
class Accounts extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get familyId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // cash, bank, credit, savings, investment, wallet
  TextColumn get currency => text().withDefault(const Constant('MXN'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get lastFourDigits => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categorias de transacciones
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get userId => text().nullable()();
  TextColumn get familyId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // income, expense
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Transacciones (ingresos, gastos, transferencias)
class Transactions extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get accountId => text()(); // Reference to Accounts.id
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income, expense, transfer
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array
  TextColumn get transferToAccountId => text().nullable()(); // Reference to Accounts.id
  TextColumn get recurringId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Presupuestos por categoria
class Budgets extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get familyId => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // weekly, monthly, yearly
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Metas de ahorro
class Goals extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get familyId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Familias/grupos
class Families extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get ownerId => text()();
  TextColumn get inviteCode => text().unique()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Miembros de familia
class FamilyMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get familyId => integer().references(Families, #id)();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))(); // owner, admin, member, viewer
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Transacciones recurrentes
class RecurringTransactions extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get accountId => text()(); // Reference to Accounts.id
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income, expense
  TextColumn get description => text().nullable()();
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextOccurrence => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// DATABASE
// ============================================================================

@DriftDatabase(tables: [
  Accounts,
  Categories,
  Transactions,
  Budgets,
  Goals,
  Families,
  FamilyMembers,
  RecurringTransactions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'finanzas_familiares');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories
        await _insertDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }

  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      // Expense categories
      ('Alimentacion', 'expense', 'restaurant', '#FF6B6B'),
      ('Transporte', 'expense', 'directions_car', '#4ECDC4'),
      ('Vivienda', 'expense', 'home', '#45B7D1'),
      ('Servicios', 'expense', 'power', '#96CEB4'),
      ('Salud', 'expense', 'favorite', '#FFEAA7'),
      ('Entretenimiento', 'expense', 'movie', '#DDA0DD'),
      ('Ropa', 'expense', 'shopping_bag', '#98D8C8'),
      ('Educacion', 'expense', 'school', '#F7DC6F'),
      ('Otros gastos', 'expense', 'more_horiz', '#BDC3C7'),
      // Income categories
      ('Salario', 'income', 'work', '#2ECC71'),
      ('Freelance', 'income', 'laptop', '#3498DB'),
      ('Inversiones', 'income', 'trending_up', '#9B59B6'),
      ('Regalos', 'income', 'card_giftcard', '#E74C3C'),
      ('Otros ingresos', 'income', 'add_circle', '#1ABC9C'),
    ];

    for (final cat in defaultCategories) {
      await into(categories).insert(CategoriesCompanion.insert(
        uuid: DateTime.now().millisecondsSinceEpoch.toString() + cat.$1,
        name: cat.$1,
        type: cat.$2,
        icon: Value(cat.$3),
        color: Value(cat.$4),
        isSystem: const Value(true),
        synced: const Value(true),
      ));
    }
  }
}
