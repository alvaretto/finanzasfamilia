import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/categories_dao.dart';

const _uuid = Uuid();

/// Siembra las categorías predefinidas basadas en el diagrama Mermaid
/// de Finanzas Familiares (nuevo-mermaid2.md)
Future<void> seedCategories(CategoriesDao dao) async {
  final existingCategories = await dao.getAllCategories();
  if (existingCategories.isNotEmpty) {
    return; // Ya sembrado
  }

  final categories = <CategoriesCompanion>[];

  // ==========================================
  // RAMA 1: LO QUE TENGO (ACTIVOS)
  // ==========================================
  final assetRootId = _uuid.v4();
  categories.add(_category(
    id: assetRootId,
    name: 'Lo que Tengo',
    icon: '💰',
    type: 'asset',
    level: 0,
    sortOrder: 1,
  ));

  // Efectivo
  final efectivoId = _uuid.v4();
  categories.add(_category(
    id: efectivoId,
    name: 'Efectivo',
    icon: '💵',
    type: 'asset',
    parentId: assetRootId,
    level: 1,
    sortOrder: 1,
  ));
  categories.addAll([
    _category(name: 'Billetera Personal', type: 'asset', parentId: efectivoId, level: 2, sortOrder: 1),
    _category(name: 'Caja Menor Casa', type: 'asset', parentId: efectivoId, level: 2, sortOrder: 2),
    _category(name: 'Alcancía / Ahorro Físico', type: 'asset', parentId: efectivoId, level: 2, sortOrder: 3),
  ]);

  // Bancos
  final bancosId = _uuid.v4();
  categories.add(_category(
    id: bancosId,
    name: 'Bancos',
    icon: '🏦',
    type: 'asset',
    parentId: assetRootId,
    level: 1,
    sortOrder: 2,
  ));

  final cuentaAhorrosId = _uuid.v4();
  categories.add(_category(
    id: cuentaAhorrosId,
    name: 'Cuenta de Ahorros',
    type: 'asset',
    parentId: bancosId,
    level: 2,
    sortOrder: 1,
  ));
  categories.addAll([
    _category(name: 'Davivienda', type: 'asset', parentId: cuentaAhorrosId, level: 3, sortOrder: 1),
    _category(name: 'Bancolombia', type: 'asset', parentId: cuentaAhorrosId, level: 3, sortOrder: 2),
  ]);

  final billeterasDigId = _uuid.v4();
  categories.add(_category(
    id: billeterasDigId,
    name: 'Billeteras Digitales',
    type: 'asset',
    parentId: bancosId,
    level: 2,
    sortOrder: 2,
  ));
  categories.addAll([
    _category(name: 'DaviPlata', type: 'asset', parentId: billeterasDigId, level: 3, sortOrder: 1),
    _category(name: 'Nequi', type: 'asset', parentId: billeterasDigId, level: 3, sortOrder: 2),
    _category(name: 'DollarApp', type: 'asset', parentId: billeterasDigId, level: 3, sortOrder: 3),
    _category(name: 'PayPal', type: 'asset', parentId: billeterasDigId, level: 3, sortOrder: 4),
  ]);

  // Inversiones
  final inversionesId = _uuid.v4();
  categories.add(_category(
    id: inversionesId,
    name: 'Inversiones',
    icon: '📈',
    type: 'asset',
    parentId: assetRootId,
    level: 1,
    sortOrder: 3,
  ));
  categories.addAll([
    _category(name: 'CDT / Fiducias', type: 'asset', parentId: inversionesId, level: 2, sortOrder: 1),
    _category(name: 'Propiedades', type: 'asset', parentId: inversionesId, level: 2, sortOrder: 2),
  ]);

  // ==========================================
  // RAMA 2: LO QUE DEBO (PASIVOS)
  // ==========================================
  final liabilityRootId = _uuid.v4();
  categories.add(_category(
    id: liabilityRootId,
    name: 'Lo que Debo',
    icon: '📉',
    type: 'liability',
    level: 0,
    sortOrder: 2,
  ));

  // Tarjetas de Crédito
  final tarjetasId = _uuid.v4();
  categories.add(_category(
    id: tarjetasId,
    name: 'Tarjetas de Crédito',
    icon: '💳',
    type: 'liability',
    parentId: liabilityRootId,
    level: 1,
    sortOrder: 1,
  ));
  categories.addAll([
    _category(name: 'Visa / Master', type: 'liability', parentId: tarjetasId, level: 2, sortOrder: 1),
    _category(name: 'Tarjeta Almacenes', type: 'liability', parentId: tarjetasId, level: 2, sortOrder: 2),
  ]);

  // Préstamos
  final prestamosId = _uuid.v4();
  categories.add(_category(
    id: prestamosId,
    name: 'Préstamos',
    icon: '🏦',
    type: 'liability',
    parentId: liabilityRootId,
    level: 1,
    sortOrder: 2,
  ));
  categories.addAll([
    _category(name: 'Hipotecario', type: 'liability', parentId: prestamosId, level: 2, sortOrder: 1),
    _category(name: 'Vehículo', type: 'liability', parentId: prestamosId, level: 2, sortOrder: 2),
    _category(name: 'Banco Pichincha', type: 'liability', parentId: prestamosId, level: 2, sortOrder: 3),
    _category(name: 'Otros Préstamos', type: 'liability', parentId: prestamosId, level: 2, sortOrder: 4),
  ]);

  // Cuentas por Pagar
  final cxpId = _uuid.v4();
  categories.add(_category(
    id: cxpId,
    name: 'Cuentas por Pagar',
    icon: '📝',
    type: 'liability',
    parentId: liabilityRootId,
    level: 1,
    sortOrder: 3,
  ));

  final impuestosPorPagarId = _uuid.v4();
  categories.addAll([
    _category(name: 'Deudas Personales', type: 'liability', parentId: cxpId, level: 2, sortOrder: 1),
    _category(name: 'Servicios Vencidos', type: 'liability', parentId: cxpId, level: 2, sortOrder: 2),
    _category(id: impuestosPorPagarId, name: 'Impuestos por Pagar', type: 'liability', parentId: cxpId, level: 2, sortOrder: 3),
    _category(name: 'Otras Cuentas por Pagar', type: 'liability', parentId: cxpId, level: 2, sortOrder: 4),
  ]);

  // Impuestos por Pagar (detalle)
  categories.addAll([
    _category(name: 'Vehicular por Pagar', type: 'liability', parentId: impuestosPorPagarId, level: 3, sortOrder: 1),
    _category(name: 'Predial por Pagar', type: 'liability', parentId: impuestosPorPagarId, level: 3, sortOrder: 2),
    _category(name: 'Renta por Pagar', type: 'liability', parentId: impuestosPorPagarId, level: 3, sortOrder: 3),
    _category(name: 'Otros Impuestos por Pagar', type: 'liability', parentId: impuestosPorPagarId, level: 3, sortOrder: 4),
  ]);

  // ==========================================
  // RAMA 3: DINERO QUE ENTRA (INGRESOS)
  // ==========================================
  final incomeRootId = _uuid.v4();
  categories.add(_category(
    id: incomeRootId,
    name: 'Dinero que Entra',
    icon: '💵',
    type: 'income',
    level: 0,
    sortOrder: 3,
  ));

  final ingresosFijosId = _uuid.v4();
  categories.add(_category(
    id: ingresosFijosId,
    name: 'Ingresos Fijos',
    type: 'income',
    parentId: incomeRootId,
    level: 1,
    sortOrder: 1,
  ));
  categories.add(_category(name: 'Salario / Nómina', type: 'income', parentId: ingresosFijosId, level: 2, sortOrder: 1));

  final ingresosVarId = _uuid.v4();
  categories.add(_category(
    id: ingresosVarId,
    name: 'Ingresos Variables / Otros',
    type: 'income',
    parentId: incomeRootId,
    level: 1,
    sortOrder: 2,
  ));
  categories.addAll([
    _category(name: 'Ventas', type: 'income', parentId: ingresosVarId, level: 2, sortOrder: 1),
    _category(name: 'Rendimientos Inversiones', type: 'income', parentId: ingresosVarId, level: 2, sortOrder: 2),
    _category(name: 'Ganancias Ocasionales', type: 'income', parentId: ingresosVarId, level: 2, sortOrder: 3),
    _category(name: 'Otros Ingresos', type: 'income', parentId: ingresosVarId, level: 2, sortOrder: 4),
  ]);

  // ==========================================
  // RAMA 4: DINERO QUE SALE (GASTOS)
  // ==========================================
  final expenseRootId = _uuid.v4();
  categories.add(_category(
    id: expenseRootId,
    name: 'Dinero que Sale',
    icon: '💸',
    type: 'expense',
    level: 0,
    sortOrder: 4,
  ));

  // 4.1 Impuestos
  final impuestosId = _uuid.v4();
  categories.add(_category(
    id: impuestosId,
    name: 'Impuestos',
    icon: '🏛️',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 1,
  ));
  categories.addAll([
    _category(name: 'Vehicular / Rodamiento', type: 'expense', parentId: impuestosId, level: 2, sortOrder: 1),
    _category(name: 'Predial / Vivienda', type: 'expense', parentId: impuestosId, level: 2, sortOrder: 2),
    _category(name: 'Renta / DIAN', type: 'expense', parentId: impuestosId, level: 2, sortOrder: 3),
    _category(name: '4x1000 / GMF', type: 'expense', parentId: impuestosId, level: 2, sortOrder: 4),
    _category(name: 'Otros Impuestos', type: 'expense', parentId: impuestosId, level: 2, sortOrder: 5),
  ]);

  // 4.2 Servicios Públicos/Privados
  final serviciosId = _uuid.v4();
  categories.add(_category(
    id: serviciosId,
    name: 'Servicios Públicos/Privados',
    icon: '💡',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 2,
  ));
  categories.addAll([
    _category(name: 'EDEQ', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 1),
    _category(name: 'EPA', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 2),
    _category(name: 'EfiGas', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 3),
    _category(name: 'Internet Hogar', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 4),
    _category(name: 'Internet Móvil', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 5),
    _category(name: 'Seguros', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 6),
    _category(name: 'Administración', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 7),
    _category(name: 'Otros Servicios', type: 'expense', parentId: serviciosId, level: 2, sortOrder: 8),
  ]);

  // 4.3 Alimentación
  final alimentacionId = _uuid.v4();
  categories.add(_category(
    id: alimentacionId,
    name: 'Alimentación',
    icon: '🥦',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 3,
  ));

  final mercadoId = _uuid.v4();
  categories.add(_category(
    id: mercadoId,
    name: 'Mercado',
    type: 'expense',
    parentId: alimentacionId,
    level: 2,
    sortOrder: 1,
  ));
  categories.addAll([
    _category(name: 'Frutas', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 1),
    _category(name: 'Verduras', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 2),
    _category(name: 'Hortalizas', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 3),
    _category(name: 'Legumbres', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 4),
    _category(name: 'Granos', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 5),
    _category(name: 'Especias', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 6),
    _category(name: 'Lácteos', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 7),
    _category(name: 'Cárnicos', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 8),
    _category(name: 'Mecato', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 9),
    _category(name: 'Panadería', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 10),
    _category(name: 'Otros Mercado', type: 'expense', parentId: mercadoId, level: 3, sortOrder: 11),
  ]);

  categories.addAll([
    _category(name: 'Restaurantes', type: 'expense', parentId: alimentacionId, level: 2, sortOrder: 2),
    _category(name: 'Domicilios', type: 'expense', parentId: alimentacionId, level: 2, sortOrder: 3),
    _category(name: 'OmniLife', type: 'expense', parentId: alimentacionId, level: 2, sortOrder: 4),
    _category(name: 'Otros Alimentación', type: 'expense', parentId: alimentacionId, level: 2, sortOrder: 5),
  ]);

  // 4.4 Transporte
  final transporteId = _uuid.v4();
  categories.add(_category(
    id: transporteId,
    name: 'Transporte',
    icon: '🚌',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 4,
  ));
  categories.addAll([
    _category(name: 'Gasolina', type: 'expense', parentId: transporteId, level: 2, sortOrder: 1),
    _category(name: 'Transporte Público', type: 'expense', parentId: transporteId, level: 2, sortOrder: 2),
    _category(name: 'Mantenimiento', type: 'expense', parentId: transporteId, level: 2, sortOrder: 3),
    _category(name: 'Seguros Chana', type: 'expense', parentId: transporteId, level: 2, sortOrder: 4),
    _category(name: 'Otros Transporte', type: 'expense', parentId: transporteId, level: 2, sortOrder: 5),
  ]);

  // 4.5 Entretenimiento
  final entretenimientoId = _uuid.v4();
  categories.add(_category(
    id: entretenimientoId,
    name: 'Entretenimiento',
    icon: '🎭',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 5,
  ));
  categories.addAll([
    _category(name: 'Cine', type: 'expense', parentId: entretenimientoId, level: 2, sortOrder: 1),
    _category(name: 'Deporte', type: 'expense', parentId: entretenimientoId, level: 2, sortOrder: 2),
    _category(name: 'Viajes', type: 'expense', parentId: entretenimientoId, level: 2, sortOrder: 3),
    _category(name: 'Otros Entretenimiento', type: 'expense', parentId: entretenimientoId, level: 2, sortOrder: 4),
  ]);

  // 4.6 Salud
  final saludId = _uuid.v4();
  categories.add(_category(
    id: saludId,
    name: 'Salud',
    icon: '🏥',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 6,
  ));
  categories.addAll([
    _category(name: 'Medicamentos', type: 'expense', parentId: saludId, level: 2, sortOrder: 1),
    _category(name: 'Consultas Médicas', type: 'expense', parentId: saludId, level: 2, sortOrder: 2),
    _category(name: 'Seguros Salud', type: 'expense', parentId: saludId, level: 2, sortOrder: 3),
    _category(name: 'Otros Salud', type: 'expense', parentId: saludId, level: 2, sortOrder: 4),
  ]);

  // 4.7 Educación
  final educacionId = _uuid.v4();
  categories.add(_category(
    id: educacionId,
    name: 'Educación',
    icon: '🎓',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 7,
  ));
  categories.addAll([
    _category(name: 'Colegiatura', type: 'expense', parentId: educacionId, level: 2, sortOrder: 1),
    _category(name: 'Cursos', type: 'expense', parentId: educacionId, level: 2, sortOrder: 2),
    _category(name: 'Libros', type: 'expense', parentId: educacionId, level: 2, sortOrder: 3),
    _category(name: 'Otros Educación', type: 'expense', parentId: educacionId, level: 2, sortOrder: 4),
  ]);

  // 4.8 Aseo
  final aseoId = _uuid.v4();
  categories.add(_category(
    id: aseoId,
    name: 'Aseo',
    icon: '🧹',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 8,
  ));
  categories.addAll([
    _category(name: 'Casa', type: 'expense', parentId: aseoId, level: 2, sortOrder: 1),
    _category(name: 'Familia', type: 'expense', parentId: aseoId, level: 2, sortOrder: 2),
    _category(name: 'Otros Aseo', type: 'expense', parentId: aseoId, level: 2, sortOrder: 3),
  ]);

  // 4.9 Otros Gastos
  final otrosGastosId = _uuid.v4();
  categories.add(_category(
    id: otrosGastosId,
    name: 'Otros Gastos',
    icon: '📦',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 9,
  ));
  categories.addAll([
    _category(name: 'Regalos / Mesada', icon: '🎁', type: 'expense', parentId: otrosGastosId, level: 2, sortOrder: 1),
    _category(name: 'Otros', type: 'expense', parentId: otrosGastosId, level: 2, sortOrder: 2),
  ]);

  // Insertar todas las categorías
  await dao.insertCategories(categories);
}

/// Helper para crear una categoría
CategoriesCompanion _category({
  String? id,
  required String name,
  String? icon,
  required String type,
  String? parentId,
  required int level,
  required int sortOrder,
}) {
  return CategoriesCompanion.insert(
    id: id ?? _uuid.v4(),
    name: name,
    icon: Value(icon),
    type: type,
    parentId: Value(parentId),
    level: Value(level),
    sortOrder: Value(sortOrder),
    isActive: const Value(true),
    isSystem: const Value(true),
  );
}
