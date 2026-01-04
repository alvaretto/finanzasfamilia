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
  TextColumn get currency => text().withDefault(const Constant('COP'))();
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
    // Mapa para guardar IDs de categorias padre
    final parentIds = <String, int>{};

    // ============================================================
    // CATEGORIAS DE GASTOS
    // ============================================================

    // 1. Alimentacion
    final alimentacionId = await _insertCategory('Alimentacion', 'expense', 'restaurant', '#ef4444');
    parentIds['alimentacion'] = alimentacionId;
    await _insertSubcategories(alimentacionId, 'expense', '#ef4444', [
      ('Supermercado', 'shopping_cart'),
      ('Restaurantes', 'restaurant'),
      ('Delivery', 'delivery_dining'),
      ('Cafeteria / Snacks', 'local_cafe'),
      ('Licores y bebidas', 'liquor'),
    ]);

    // 2. Vivienda
    final viviendaId = await _insertCategory('Vivienda', 'expense', 'home', '#3b82f6');
    parentIds['vivienda'] = viviendaId;
    await _insertSubcategories(viviendaId, 'expense', '#3b82f6', [
      ('Renta / Hipoteca', 'house'),
      ('Administracion', 'apartment'),
      ('Agua', 'water_drop'),
      ('Energia electrica', 'bolt'),
      ('Gas', 'local_fire_department'),
      ('Internet / TV / Telefono', 'wifi'),
      ('Mantenimiento hogar', 'handyman'),
      ('Seguro hogar', 'security'),
    ]);

    // 3. Transporte
    final transporteId = await _insertCategory('Transporte', 'expense', 'directions_car', '#22c55e');
    parentIds['transporte'] = transporteId;
    await _insertSubcategories(transporteId, 'expense', '#22c55e', [
      ('Combustible', 'local_gas_station'),
      ('Transporte publico', 'directions_bus'),
      ('Taxi / Uber', 'local_taxi'),
      ('Mantenimiento vehiculo', 'car_repair'),
      ('Seguro vehiculo', 'verified_user'),
      ('Parqueadero', 'local_parking'),
      ('Peajes', 'toll'),
    ]);

    // 4. Salud
    final saludId = await _insertCategory('Salud', 'expense', 'favorite', '#ec4899');
    parentIds['salud'] = saludId;
    await _insertSubcategories(saludId, 'expense', '#ec4899', [
      ('Medicina prepagada / EPS', 'health_and_safety'),
      ('Consultas medicas', 'medical_services'),
      ('Medicamentos', 'medication'),
      ('Examenes / Laboratorio', 'biotech'),
      ('Odontologia', 'dentistry'),
      ('Optica', 'visibility'),
      ('Terapias', 'psychology'),
    ]);

    // 5. Bienestar
    final bienestarId = await _insertCategory('Bienestar', 'expense', 'spa', '#a855f7');
    parentIds['bienestar'] = bienestarId;
    await _insertSubcategories(bienestarId, 'expense', '#a855f7', [
      ('Gimnasio / Deportes', 'fitness_center'),
      ('Cuidado personal', 'face'),
      ('Productos de aseo', 'soap'),
      ('Cosmeticos', 'brush'),
      ('Salud mental', 'self_improvement'),
    ]);

    // 6. Educacion
    final educacionId = await _insertCategory('Educacion', 'expense', 'school', '#f59e0b');
    parentIds['educacion'] = educacionId;
    await _insertSubcategories(educacionId, 'expense', '#f59e0b', [
      ('Matricula / Pension', 'school'),
      ('Cursos / Capacitaciones', 'cast_for_education'),
      ('Libros / Material', 'menu_book'),
      ('Utiles escolares', 'edit'),
      ('Uniformes', 'checkroom'),
    ]);

    // 7. Ropa y Calzado
    final ropaId = await _insertCategory('Ropa y Calzado', 'expense', 'shopping_bag', '#06b6d4');
    parentIds['ropa'] = ropaId;
    await _insertSubcategories(ropaId, 'expense', '#06b6d4', [
      ('Ropa', 'dry_cleaning'),
      ('Calzado', 'ice_skating'),
      ('Accesorios', 'watch'),
      ('Ropa deportiva', 'sports'),
    ]);

    // 8. Entretenimiento
    final entretenimientoId = await _insertCategory('Entretenimiento', 'expense', 'movie', '#8b5cf6');
    parentIds['entretenimiento'] = entretenimientoId;
    await _insertSubcategories(entretenimientoId, 'expense', '#8b5cf6', [
      ('Streaming', 'play_circle'),
      ('Cine / Teatro', 'theaters'),
      ('Eventos / Conciertos', 'celebration'),
      ('Videojuegos', 'sports_esports'),
      ('Hobbies', 'palette'),
      ('Libros / Revistas', 'auto_stories'),
      ('Salidas / Bares', 'nightlife'),
      ('Vacaciones / Viajes', 'flight'),
    ]);

    // 9. Tecnologia
    final tecnologiaId = await _insertCategory('Tecnologia', 'expense', 'devices', '#64748b');
    parentIds['tecnologia'] = tecnologiaId;
    await _insertSubcategories(tecnologiaId, 'expense', '#64748b', [
      ('Celular / Plan movil', 'smartphone'),
      ('Equipos', 'computer'),
      ('Accesorios tech', 'headphones'),
      ('Software / Apps', 'apps'),
      ('Reparaciones', 'build'),
    ]);

    // 10. Mascotas
    final mascotasId = await _insertCategory('Mascotas', 'expense', 'pets', '#f97316');
    parentIds['mascotas'] = mascotasId;
    await _insertSubcategories(mascotasId, 'expense', '#f97316', [
      ('Alimento mascota', 'restaurant'),
      ('Veterinario', 'vaccines'),
      ('Accesorios mascota', 'shopping_bag'),
      ('Peluqueria mascota', 'content_cut'),
    ]);

    // 11. Servicios Financieros
    final financierosId = await _insertCategory('Servicios Financieros', 'expense', 'account_balance', '#0891b2');
    parentIds['financieros'] = financierosId;
    await _insertSubcategories(financierosId, 'expense', '#0891b2', [
      ('Cuota manejo tarjeta', 'credit_card'),
      ('Comisiones bancarias', 'receipt'),
      ('Seguros de vida', 'security'),
      ('Intereses creditos', 'percent'),
    ]);

    // 12. Impuestos
    final impuestosId = await _insertCategory('Impuestos', 'expense', 'receipt_long', '#dc2626');
    parentIds['impuestos'] = impuestosId;
    await _insertSubcategories(impuestosId, 'expense', '#dc2626', [
      ('Declaracion renta', 'description'),
      ('IVA', 'calculate'),
      ('Otros impuestos', 'receipt'),
    ]);

    // 13. Regalos y Donaciones
    final regalosGastoId = await _insertCategory('Regalos y Donaciones', 'expense', 'card_giftcard', '#e11d48');
    parentIds['regalos_gasto'] = regalosGastoId;
    await _insertSubcategories(regalosGastoId, 'expense', '#e11d48', [
      ('Regalos', 'redeem'),
      ('Donaciones', 'volunteer_activism'),
      ('Propinas', 'paid'),
    ]);

    // 14. Suscripciones
    final suscripcionesId = await _insertCategory('Suscripciones', 'expense', 'subscriptions', '#7c3aed');
    parentIds['suscripciones'] = suscripcionesId;
    await _insertSubcategories(suscripcionesId, 'expense', '#7c3aed', [
      ('Membresias', 'card_membership'),
      ('Suscripciones digitales', 'cloud'),
      ('Clubes / Asociaciones', 'groups'),
    ]);

    // 15. Otros Gastos
    await _insertCategory('Otros Gastos', 'expense', 'more_horiz', '#6b7280');

    // ============================================================
    // CATEGORIAS DE INGRESOS
    // ============================================================

    // 1. Salario / Empleo
    final salarioId = await _insertCategory('Salario / Empleo', 'income', 'work', '#22c55e');
    parentIds['salario'] = salarioId;
    await _insertSubcategories(salarioId, 'income', '#22c55e', [
      ('Salario mensual', 'payments'),
      ('Bonificaciones', 'celebration'),
      ('Comisiones', 'trending_up'),
      ('Horas extras', 'schedule'),
      ('Prima / Aguinaldo', 'card_giftcard'),
    ]);

    // 2. Negocio / Freelance
    final freelanceId = await _insertCategory('Negocio / Freelance', 'income', 'laptop', '#3b82f6');
    parentIds['freelance'] = freelanceId;
    await _insertSubcategories(freelanceId, 'income', '#3b82f6', [
      ('Ventas', 'store'),
      ('Servicios', 'handyman'),
      ('Consultoria', 'support_agent'),
      ('Proyectos', 'assignment'),
    ]);

    // 3. Inversiones
    final inversionesId = await _insertCategory('Inversiones', 'income', 'trending_up', '#8b5cf6');
    parentIds['inversiones'] = inversionesId;
    await _insertSubcategories(inversionesId, 'income', '#8b5cf6', [
      ('Dividendos', 'attach_money'),
      ('Intereses', 'percent'),
      ('Ganancias capital', 'show_chart'),
      ('Rendimientos', 'insights'),
    ]);

    // 4. Arriendos
    final arriendosId = await _insertCategory('Arriendos', 'income', 'home_work', '#f97316');
    parentIds['arriendos'] = arriendosId;
    await _insertSubcategories(arriendosId, 'income', '#f97316', [
      ('Arriendo inmueble', 'apartment'),
      ('Arriendo vehiculo', 'directions_car'),
      ('Arriendo equipos', 'devices'),
    ]);

    // 5. Otros Ingresos
    final otrosIngresosId = await _insertCategory('Otros Ingresos', 'income', 'add_circle', '#6b7280');
    parentIds['otros_ingresos'] = otrosIngresosId;
    await _insertSubcategories(otrosIngresosId, 'income', '#6b7280', [
      ('Reembolsos', 'undo'),
      ('Regalos recibidos', 'redeem'),
      ('Venta articulos', 'sell'),
      ('Subsidios', 'account_balance'),
      ('Pension', 'elderly'),
    ]);

    // 6. Ingresos Extraordinarios
    await _insertCategory('Ingresos Extraordinarios', 'income', 'stars', '#eab308');
  }

  /// Inserta una categoria principal y retorna su ID
  Future<int> _insertCategory(String name, String type, String icon, String color) async {
    final uuid = '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}';
    return await into(categories).insert(CategoriesCompanion.insert(
      uuid: uuid,
      name: name,
      type: type,
      icon: Value(icon),
      color: Value(color),
      isSystem: const Value(true),
      synced: const Value(true),
    ));
  }

  /// Inserta subcategorias para una categoria padre
  Future<void> _insertSubcategories(
    int parentId,
    String type,
    String color,
    List<(String name, String icon)> subcats,
  ) async {
    for (final sub in subcats) {
      final uuid = '${DateTime.now().millisecondsSinceEpoch}_${sub.$1.replaceAll(' ', '_')}';
      await into(categories).insert(CategoriesCompanion.insert(
        uuid: uuid,
        name: sub.$1,
        type: type,
        icon: Value(sub.$2),
        color: Value(color),
        parentId: Value(parentId),
        isSystem: const Value(true),
        synced: const Value(true),
      ));
    }
  }
}
