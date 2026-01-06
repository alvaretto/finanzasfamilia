import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

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
  TextColumn get currency => text().withDefault(const Constant('COP'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get lastFourDigits => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  TextColumn get debtSubtype => text().nullable()(); // Subtipo de deuda (loan, payable)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categorias de transacciones
class Categories extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text().nullable()();
  TextColumn get familyId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // income, expense
  TextColumn get icon => text().nullable()();
  TextColumn get emoji => text().nullable()(); // Emoji representativo
  TextColumn get color => text().nullable()();
  TextColumn get parentId => text().nullable()(); // Reference to parent category
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transacciones (ingresos, gastos, transferencias)
class Transactions extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get accountId => text()(); // Reference to Accounts.id
  TextColumn get categoryId => text().nullable()(); // Reference to Categories.id
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

  // ============ NUEVOS CAMPOS v3 - Detalles del artículo ============
  TextColumn get itemDescription => text().nullable()(); // Qué compraste (ej: "Arroz")
  TextColumn get brand => text().nullable()(); // Marca (ej: "Roa")
  RealColumn get quantity => real().nullable()(); // Cantidad (ej: 10)
  TextColumn get unitId => text().nullable()(); // Reference to Units.id
  RealColumn get unitPrice => real().nullable()(); // Precio unitario calculado

  // ============ NUEVOS CAMPOS v3 - Lugar de compra ============
  TextColumn get establishmentId => text().nullable()(); // Reference to Establishments.id

  // ============ NUEVOS CAMPOS v3 - Forma y medio de pago ============
  TextColumn get paymentMethod => text().nullable()(); // credit, cash
  TextColumn get paymentMedium => text().nullable()(); // credit_card, fiado, cash, bank_transfer, app_transfer
  TextColumn get paymentSubmedium => text().nullable()(); // davivienda, bancolombia, nequi, daviplata, dollarapp

  @override
  Set<Column> get primaryKey => {id};
}

/// Unidades de medida (Libra, Kg, Unidad, etc.)
class Units extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text().withLength(min: 1, max: 50)(); // Libra, Kilogramo, etc.
  TextColumn get shortName => text().withLength(min: 1, max: 10)(); // lb, kg, ud, etc.
  TextColumn get category => text()(); // weight, volume, length, unit
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Establecimientos (lugares de compra con autocompletado)
class Establishments extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)(); // Nombre del lugar
  TextColumn get address => text().nullable()(); // Dirección
  TextColumn get phone => text().nullable()(); // Teléfono
  TextColumn get category => text().nullable()(); // supermercado, restaurante, tienda, etc.
  TextColumn get icon => text().nullable()();
  IntColumn get useCount => integer().withDefault(const Constant(0))(); // Para ordenar por uso
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
  TextColumn get categoryId => text()(); // Reference to Categories.id
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
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get ownerId => text()();
  TextColumn get inviteCode => text().unique()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Miembros de familia
class FamilyMembers extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get familyId => text()(); // Reference to Families.id
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))(); // owner, admin, member, viewer
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transacciones recurrentes
class RecurringTransactions extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get userId => text()();
  TextColumn get accountId => text()(); // Reference to Accounts.id
  TextColumn get categoryId => text().nullable()(); // Reference to Categories.id
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
  Units,
  Establishments,
])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;

  /// Returns the singleton instance of AppDatabase
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  /// Resets the singleton instance (for testing only)
  @visibleForTesting
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }

  /// Sets a custom instance (for testing/mocking only)
  @visibleForTesting
  static void setInstance(AppDatabase db) {
    _instance = db;
  }

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

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
        // Insert default units
        await _insertDefaultUnits();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migración v2 -> v3: Nuevos campos en Transactions + tablas Units y Establishments
        if (from < 3) {
          // Crear nuevas tablas
          await m.createTable(units);
          await m.createTable(establishments);

          // Agregar nuevas columnas a Transactions
          await m.addColumn(transactions, transactions.itemDescription);
          await m.addColumn(transactions, transactions.brand);
          await m.addColumn(transactions, transactions.quantity);
          await m.addColumn(transactions, transactions.unitId);
          await m.addColumn(transactions, transactions.unitPrice);
          await m.addColumn(transactions, transactions.establishmentId);
          await m.addColumn(transactions, transactions.paymentMethod);
          await m.addColumn(transactions, transactions.paymentMedium);
          await m.addColumn(transactions, transactions.paymentSubmedium);

          // Insertar unidades por defecto
          await _insertDefaultUnits();
        }

        // Migración v3 -> v4: Subtipo de deuda en Accounts
        if (from < 4) {
          await m.addColumn(accounts, accounts.debtSubtype);
        }
      },
    );
  }

  Future<void> _insertDefaultCategories() async {
    // Mapa para guardar IDs de categorias padre
    final parentIds = <String, String>{};

    // ============================================================
    // CATEGORIAS DE GASTOS
    // ============================================================

    // 1. Alimentacion
    final alimentacionId = await _insertCategory('Alimentacion', 'expense', 'restaurant', '🍔', '#ef4444');
    parentIds['alimentacion'] = alimentacionId;
    await _insertSubcategories(alimentacionId, 'expense', '#ef4444', [
      ('Supermercado', 'shopping_cart', '🛒'),
      ('Restaurantes', 'restaurant', '🍽️'),
      ('Delivery', 'delivery_dining', '🚚'),
      ('Cafeteria / Snacks', 'local_cafe', '☕'),
      ('Licores y bebidas', 'liquor', '🍺'),
    ]);

    // 2. Vivienda
    final viviendaId = await _insertCategory('Vivienda', 'expense', 'home', '🏠', '#3b82f6');
    parentIds['vivienda'] = viviendaId;
    await _insertSubcategories(viviendaId, 'expense', '#3b82f6', [
      ('Renta / Hipoteca', 'house', '🏡'),
      ('Administracion', 'apartment', '🏢'),
      ('Agua', 'water_drop', '💧'),
      ('Energia electrica', 'bolt', '⚡'),
      ('Gas', 'local_fire_department', '🔥'),
      ('Internet / TV / Telefono', 'wifi', '📡'),
      ('Mantenimiento hogar', 'handyman', '🔧'),
      ('Seguro hogar', 'security', '🛡️'),
    ]);

    // 3. Transporte
    final transporteId = await _insertCategory('Transporte', 'expense', 'directions_car', '🚗', '#22c55e');
    parentIds['transporte'] = transporteId;
    await _insertSubcategories(transporteId, 'expense', '#22c55e', [
      ('Combustible', 'local_gas_station', '⛽'),
      ('Transporte publico', 'directions_bus', '🚌'),
      ('Taxi / Uber', 'local_taxi', '🚕'),
      ('Mantenimiento vehiculo', 'car_repair', '🔧'),
      ('Seguro vehiculo', 'verified_user', '🛡️'),
      ('Parqueadero', 'local_parking', '🅿️'),
      ('Peajes', 'toll', '🚧'),
    ]);

    // 4. Salud
    final saludId = await _insertCategory('Salud', 'expense', 'favorite', '❤️', '#ec4899');
    parentIds['salud'] = saludId;
    await _insertSubcategories(saludId, 'expense', '#ec4899', [
      ('Medicina prepagada / EPS', 'health_and_safety', '🏥'),
      ('Consultas medicas', 'medical_services', '👨‍⚕️'),
      ('Medicamentos', 'medication', '💊'),
      ('Examenes / Laboratorio', 'biotech', '🔬'),
      ('Odontologia', 'dentistry', '🦷'),
      ('Optica', 'visibility', '👓'),
      ('Terapias', 'psychology', '🧠'),
    ]);

    // 5. Bienestar
    final bienestarId = await _insertCategory('Bienestar', 'expense', 'spa', '💆', '#a855f7');
    parentIds['bienestar'] = bienestarId;
    await _insertSubcategories(bienestarId, 'expense', '#a855f7', [
      ('Gimnasio / Deportes', 'fitness_center', '💪'),
      ('Cuidado personal', 'face', '✨'),
      ('Productos de aseo', 'soap', '🧼'),
      ('Cosmeticos', 'brush', '💄'),
      ('Salud mental', 'self_improvement', '🧘'),
    ]);

    // 6. Educacion
    final educacionId = await _insertCategory('Educacion', 'expense', 'school', '🎓', '#f59e0b');
    parentIds['educacion'] = educacionId;
    await _insertSubcategories(educacionId, 'expense', '#f59e0b', [
      ('Matricula / Pension', 'school', '🏫'),
      ('Cursos / Capacitaciones', 'cast_for_education', '📚'),
      ('Libros / Material', 'menu_book', '📖'),
      ('Utiles escolares', 'edit', '✏️'),
      ('Uniformes', 'checkroom', '👔'),
    ]);

    // 7. Ropa y Calzado
    final ropaId = await _insertCategory('Ropa y Calzado', 'expense', 'shopping_bag', '👗', '#06b6d4');
    parentIds['ropa'] = ropaId;
    await _insertSubcategories(ropaId, 'expense', '#06b6d4', [
      ('Ropa', 'dry_cleaning', '👕'),
      ('Calzado', 'ice_skating', '👟'),
      ('Accesorios', 'watch', '⌚'),
      ('Ropa deportiva', 'sports', '🏃'),
    ]);

    // 8. Entretenimiento
    final entretenimientoId = await _insertCategory('Entretenimiento', 'expense', 'movie', '🎬', '#8b5cf6');
    parentIds['entretenimiento'] = entretenimientoId;
    await _insertSubcategories(entretenimientoId, 'expense', '#8b5cf6', [
      ('Streaming', 'play_circle', '📺'),
      ('Cine / Teatro', 'theaters', '🎭'),
      ('Eventos / Conciertos', 'celebration', '🎉'),
      ('Videojuegos', 'sports_esports', '🎮'),
      ('Hobbies', 'palette', '🎨'),
      ('Libros / Revistas', 'menu_book', '📚'),
      ('Salidas / Vida social', 'nightlife', '🌟'),
      ('Vacaciones / Viajes', 'flight', '✈️'),
    ]);

    // 9. Tecnologia
    final tecnologiaId = await _insertCategory('Tecnologia', 'expense', 'devices', '💻', '#64748b');
    parentIds['tecnologia'] = tecnologiaId;
    await _insertSubcategories(tecnologiaId, 'expense', '#64748b', [
      ('Celular / Telefonia', 'smartphone', '📱'),
      ('Equipos / Hardware', 'computer', '🖥️'),
      ('Accesorios tecnologicos', 'headphones', '🎧'),
      ('Software / Apps', 'apps', '📲'),
      ('Reparaciones', 'build', '🔧'),
    ]);

    // 10. Mascotas
    final mascotasId = await _insertCategory('Mascotas', 'expense', 'pets', '🐾', '#f97316');
    parentIds['mascotas'] = mascotasId;
    await _insertSubcategories(mascotasId, 'expense', '#f97316', [
      ('Alimento', 'set_meal', '🍖'),
      ('Veterinario', 'local_hospital', '🏥'),
      ('Accesorios', 'shopping_bag', '🎾'),
      ('Peluqueria / Grooming', 'cut', '✂️'),
    ]);

    // 11. Servicios Financieros
    final serviciosFinId = await _insertCategory('Servicios Financieros', 'expense', 'account_balance', '🏦', '#0891b2');
    parentIds['servicios_financieros'] = serviciosFinId;
    await _insertSubcategories(serviciosFinId, 'expense', '#0891b2', [
      ('Cuota manejo', 'credit_card', '💳'),
      ('Comisiones bancarias', 'receipt', '🧾'),
      ('Seguros de vida', 'shield', '🛡️'),
      ('Intereses', 'trending_down', '📉'),
    ]);

    // 12. Impuestos
    final impuestosId = await _insertCategory('Impuestos', 'expense', 'receipt_long', '📋', '#dc2626');
    parentIds['impuestos'] = impuestosId;
    await _insertSubcategories(impuestosId, 'expense', '#dc2626', [
      ('Declaracion de renta', 'description', '📄'),
      ('IVA', 'percent', '💸'),
      ('Otros impuestos', 'gavel', '⚖️'),
    ]);

    // 13. Regalos y Donaciones
    final regalosId = await _insertCategory('Regalos y Donaciones', 'expense', 'card_giftcard', '🎁', '#e11d48');
    parentIds['regalos'] = regalosId;
    await _insertSubcategories(regalosId, 'expense', '#e11d48', [
      ('Regalos', 'redeem', '🎀'),
      ('Donaciones', 'volunteer_activism', '🤝'),
      ('Propinas', 'payments', '💵'),
    ]);

    // 14. Suscripciones
    final suscripcionesId = await _insertCategory('Suscripciones', 'expense', 'subscriptions', '📱', '#7c3aed');
    parentIds['suscripciones'] = suscripcionesId;
    await _insertSubcategories(suscripcionesId, 'expense', '#7c3aed', [
      ('Membresias', 'card_membership', '💳'),
      ('Suscripciones digitales', 'subscriptions', '📲'),
      ('Clubes', 'groups', '👥'),
    ]);

    // 15. Otros Gastos
    await _insertCategory('Otros Gastos', 'expense', 'more_horiz', '📦', '#6b7280');

    // ============================================================
    // CATEGORIAS DE INGRESOS
    // ============================================================

    // 1. Salario / Empleo
    final salarioId = await _insertCategory('Salario / Empleo', 'income', 'work', '💼', '#22c55e');
    parentIds['salario'] = salarioId;
    await _insertSubcategories(salarioId, 'income', '#22c55e', [
      ('Salario mensual', 'attach_money', '💰'),
      ('Bonificaciones', 'star', '⭐'),
      ('Comisiones', 'trending_up', '📈'),
      ('Horas extras', 'schedule', '⏰'),
      ('Prima', 'card_giftcard', '🎁'),
    ]);

    // 2. Negocio / Freelance
    final negocioId = await _insertCategory('Negocio / Freelance', 'income', 'laptop', '💻', '#3b82f6');
    parentIds['negocio'] = negocioId;
    await _insertSubcategories(negocioId, 'income', '#3b82f6', [
      ('Ventas', 'storefront', '🏪'),
      ('Servicios', 'handshake', '🤝'),
      ('Consultoria', 'lightbulb', '💡'),
      ('Proyectos', 'folder', '📁'),
    ]);

    // 3. Inversiones
    final inversionesId = await _insertCategory('Inversiones', 'income', 'trending_up', '📈', '#8b5cf6');
    parentIds['inversiones'] = inversionesId;
    await _insertSubcategories(inversionesId, 'income', '#8b5cf6', [
      ('Dividendos', 'pie_chart', '📊'),
      ('Intereses', 'savings', '💵'),
      ('Ganancias de capital', 'show_chart', '📉'),
      ('Rendimientos', 'account_balance', '🏦'),
    ]);

    // 4. Arriendos
    final arriendosId = await _insertCategory('Arriendos', 'income', 'home_work', '🏘️', '#f97316');
    parentIds['arriendos'] = arriendosId;
    await _insertSubcategories(arriendosId, 'income', '#f97316', [
      ('Arriendo de inmueble', 'apartment', '🏢'),
      ('Arriendo de vehiculo', 'directions_car', '🚗'),
      ('Arriendo de equipos', 'devices', '🖥️'),
    ]);

    // 5. Otros Ingresos
    final otrosIngresosId = await _insertCategory('Otros Ingresos', 'income', 'add_circle', '➕', '#6b7280');
    parentIds['otros_ingresos'] = otrosIngresosId;
    await _insertSubcategories(otrosIngresosId, 'income', '#6b7280', [
      ('Reembolsos', 'receipt_long', '🧾'),
      ('Regalos recibidos', 'redeem', '🎁'),
      ('Venta articulos', 'sell', '💸'),
      ('Subsidios', 'account_balance', '💰'),
      ('Pension', 'elderly', '👴'),
    ]);

    // 6. Ingresos Extraordinarios
    await _insertCategory('Ingresos Extraordinarios', 'income', 'stars', '⭐', '#eab308');
  }

  /// Inserta una categoria principal y retorna su ID (UUID)
  Future<String> _insertCategory(String name, String type, String icon, String emoji, String color) async {
    final id = _uuid.v4();
    await into(categories).insert(CategoriesCompanion.insert(
      id: id,
      name: name,
      type: type,
      icon: Value(icon),
      emoji: Value(emoji),
      color: Value(color),
      isSystem: const Value(true),
      isSynced: const Value(true),
    ));
    return id;
  }

  /// Inserta subcategorias para una categoria padre
  Future<void> _insertSubcategories(
    String parentId,
    String type,
    String color,
    List<(String name, String icon, String emoji)> subcats,
  ) async {
    for (final sub in subcats) {
      final id = _uuid.v4();
      await into(categories).insert(CategoriesCompanion.insert(
        id: id,
        name: sub.$1,
        type: type,
        icon: Value(sub.$2),
        emoji: Value(sub.$3),
        color: Value(color),
        parentId: Value(parentId),
        isSystem: const Value(true),
        isSynced: const Value(true),
      ));
    }
  }

  /// Inserta unidades de medida por defecto
  Future<void> _insertDefaultUnits() async {
    final defaultUnits = <(String id, String name, String shortName, String category)>[
      // Peso
      ('unit_libra', 'Libra', 'lb', 'weight'),
      ('unit_kg', 'Kilogramo', 'kg', 'weight'),
      ('unit_gramo', 'Gramo', 'g', 'weight'),
      ('unit_arroba', 'Arroba', '@', 'weight'),
      ('unit_onza', 'Onza', 'oz', 'weight'),

      // Volumen
      ('unit_litro', 'Litro', 'L', 'volume'),
      ('unit_ml', 'Mililitro', 'ml', 'volume'),
      ('unit_galon', 'Galón', 'gal', 'volume'),
      ('unit_botella', 'Botella', 'bot', 'volume'),

      // Longitud
      ('unit_metro', 'Metro', 'm', 'length'),
      ('unit_cm', 'Centímetro', 'cm', 'length'),
      ('unit_pulgada', 'Pulgada', 'in', 'length'),

      // Unidades discretas
      ('unit_unidad', 'Unidad', 'ud', 'unit'),
      ('unit_paquete', 'Paquete', 'paq', 'unit'),
      ('unit_caja', 'Caja', 'caja', 'unit'),
      ('unit_docena', 'Docena', 'doc', 'unit'),
      ('unit_par', 'Par', 'par', 'unit'),
      ('unit_bolsa', 'Bolsa', 'bolsa', 'unit'),
      ('unit_rollo', 'Rollo', 'rollo', 'unit'),
      ('unit_lata', 'Lata', 'lata', 'unit'),
      ('unit_frasco', 'Frasco', 'frasco', 'unit'),
      ('unit_sobre', 'Sobre', 'sobre', 'unit'),
      ('unit_porcion', 'Porción', 'porc', 'unit'),
    ];

    for (final unit in defaultUnits) {
      await into(units).insert(UnitsCompanion.insert(
        id: unit.$1,
        name: unit.$2,
        shortName: unit.$3,
        category: unit.$4,
        isSystem: const Value(true),
      ));
    }
  }
}
