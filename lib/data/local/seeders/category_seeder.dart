import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/categories_dao.dart';

const _uuid = Uuid();

/// Namespace UUID para generar IDs determinísticos de categorías del sistema.
/// Esto asegura que las mismas categorías tengan los mismos IDs en cualquier
/// instalación, permitiendo sincronización correcta con PowerSync.
const _systemCategoryNamespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

/// Genera un UUID determinístico para una categoría del sistema.
/// Usa UUID v5 (basado en SHA-1) con el namespace y el nombre de la categoría.
String _deterministicId(String categoryName, String type) {
  return _uuid.v5(_systemCategoryNamespace, '$type:$categoryName');
}

/// Siembra las categorías predefinidas basadas en el diagrama Mermaid
/// de Finanzas Familiares (nuevo-mermaid2.md)
///
/// IMPORTANTE: Usa UUIDs determinísticos para que las categorías del sistema
/// tengan los mismos IDs en cualquier instalación. Esto es crítico para
/// que PowerSync pueda sincronizar correctamente con Supabase.
Future<void> seedCategories(CategoriesDao dao) async {
  final existingCategories = await dao.getAllCategories();
  if (existingCategories.isNotEmpty) {
    return; // Ya sembrado
  }

  final categories = <CategoriesCompanion>[];

  // ==========================================
  // RAMA 1: LO QUE TENGO (ACTIVOS)
  // ==========================================
  final assetRootId = _deterministicId('Lo que Tengo', 'asset');
  categories.add(_category(
    id: assetRootId,
    name: 'Lo que Tengo',
    icon: '💰',
    type: 'asset',
    level: 0,
    sortOrder: 1,
  ));

  // Efectivo
  final efectivoId = _deterministicId('Efectivo', 'asset');
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
  final bancosId = _deterministicId('Bancos', 'asset');
  categories.add(_category(
    id: bancosId,
    name: 'Bancos',
    icon: '🏦',
    type: 'asset',
    parentId: assetRootId,
    level: 1,
    sortOrder: 2,
  ));

  final cuentaAhorrosId = _deterministicId('Cuenta de Ahorros', 'asset');
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

  final billeterasDigId = _deterministicId('Billeteras Digitales', 'asset');
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
  final inversionesId = _deterministicId('Inversiones', 'asset');
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
  final liabilityRootId = _deterministicId('Lo que Debo', 'liability');
  categories.add(_category(
    id: liabilityRootId,
    name: 'Lo que Debo',
    icon: '📉',
    type: 'liability',
    level: 0,
    sortOrder: 2,
  ));

  // Tarjetas de Crédito
  final tarjetasId = _deterministicId('Tarjetas de Crédito', 'liability');
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
  final prestamosId = _deterministicId('Préstamos', 'liability');
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
  final cxpId = _deterministicId('Cuentas por Pagar', 'liability');
  categories.add(_category(
    id: cxpId,
    name: 'Cuentas por Pagar',
    icon: '📝',
    type: 'liability',
    parentId: liabilityRootId,
    level: 1,
    sortOrder: 3,
  ));

  final impuestosPorPagarId = _deterministicId('Impuestos por Pagar', 'liability');
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
  final incomeRootId = _deterministicId('Dinero que Entra', 'income');
  categories.add(_category(
    id: incomeRootId,
    name: 'Dinero que Entra',
    icon: '💵',
    type: 'income',
    level: 0,
    sortOrder: 3,
  ));

  final ingresosFijosId = _deterministicId('Ingresos Fijos', 'income');
  categories.add(_category(
    id: ingresosFijosId,
    name: 'Ingresos Fijos',
    type: 'income',
    parentId: incomeRootId,
    level: 1,
    sortOrder: 1,
  ));
  categories.add(_category(name: 'Salario / Nómina', type: 'income', parentId: ingresosFijosId, level: 2, sortOrder: 1));

  final ingresosVarId = _deterministicId('Ingresos Variables / Otros', 'income');
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
  final expenseRootId = _deterministicId('Dinero que Sale', 'expense');
  categories.add(_category(
    id: expenseRootId,
    name: 'Dinero que Sale',
    icon: '💸',
    type: 'expense',
    level: 0,
    sortOrder: 4,
  ));

  // 4.1 Impuestos
  final impuestosId = _deterministicId('Impuestos', 'expense');
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
  final serviciosId = _deterministicId('Servicios Públicos/Privados', 'expense');
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
  final alimentacionId = _deterministicId('Alimentación', 'expense');
  categories.add(_category(
    id: alimentacionId,
    name: 'Alimentación',
    icon: '🥦',
    type: 'expense',
    parentId: expenseRootId,
    level: 1,
    sortOrder: 3,
  ));

  final mercadoId = _deterministicId('Mercado', 'expense');
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
  final transporteId = _deterministicId('Transporte', 'expense');
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
  final entretenimientoId = _deterministicId('Entretenimiento', 'expense');
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
  final saludId = _deterministicId('Salud', 'expense');
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
  final educacionId = _deterministicId('Educación', 'expense');
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
  final aseoId = _deterministicId('Aseo', 'expense');
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
  final otrosGastosId = _deterministicId('Otros Gastos', 'expense');
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
///
/// Si no se proporciona ID, genera uno determinístico basado en el nombre y tipo.
/// Esto asegura que las mismas categorías tengan los mismos IDs en cualquier
/// instalación, permitiendo sincronización correcta con PowerSync/Supabase.
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
    id: id ?? _deterministicId(name, type),
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
