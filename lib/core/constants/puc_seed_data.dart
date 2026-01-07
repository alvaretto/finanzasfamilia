/// Datos semilla del Plan Único de Cuentas (PUC) colombiano
///
/// Esta estructura es INMUTABLE y representa la base contable del sistema.
/// Los usuarios crean instancias (Accounts) que referencian estos grupos.
library;

import '../database/tables/account_puc_tables.dart';

/// Clases Contables PUC (5 clases básicas)
const List<AccountClassSeed> accountClassesSeeds = [
  AccountClassSeed(
    id: 1,
    name: 'Activo',
    presentationName: 'Lo que Tengo',
    description: 'Bienes y derechos que posees: efectivo, cuentas bancarias, propiedades, inversiones',
    displayOrder: 1,
  ),
  AccountClassSeed(
    id: 2,
    name: 'Pasivo',
    presentationName: 'Lo que Debo',
    description: 'Obligaciones y deudas: tarjetas de crédito, préstamos, cuentas por pagar',
    displayOrder: 2,
  ),
  AccountClassSeed(
    id: 3,
    name: 'Patrimonio',
    presentationName: 'Mis Ahorros Netos',
    description: 'Tu riqueza real: la diferencia entre lo que tienes y lo que debes',
    displayOrder: 3,
  ),
  AccountClassSeed(
    id: 4,
    name: 'Ingresos',
    presentationName: 'Dinero que Recibo',
    description: 'Todo el dinero que entra: salario, negocios, inversiones, arriendos',
    displayOrder: 4,
  ),
  AccountClassSeed(
    id: 5,
    name: 'Gastos',
    presentationName: 'Dinero que Pago',
    description: 'Todo el dinero que sale: vivienda, transporte, alimentación, entretenimiento',
    displayOrder: 5,
  ),
];

/// Grupos de Cuentas PUC (Contenedores Rígidos)
///
/// Mapeo específico para usuarios colombianos en modo Personal
const List<AccountGroupSeed> accountGroupsSeeds = [
  // ========================================================================
  // CLASS 1: ACTIVOS (Lo que Tengo)
  // ========================================================================

  AccountGroupSeed(
    id: '1105',
    classId: 1,
    technicalName: 'Caja General',
    friendlyName: 'Efectivo y Bolsillos',
    nature: AccountNature.DEBIT,
    icon: 'payments',
    color: '#10b981',
    displayOrder: 1,
  ),
  AccountGroupSeed(
    id: '1110',
    classId: 1,
    technicalName: 'Bancos',
    friendlyName: 'Bancos / Nequi / Daviplata',
    nature: AccountNature.DEBIT,
    icon: 'account_balance',
    color: '#3b82f6',
    displayOrder: 2,
  ),
  AccountGroupSeed(
    id: '1305',
    classId: 1,
    technicalName: 'Clientes',
    friendlyName: 'Dinero que me Deben',
    nature: AccountNature.DEBIT,
    icon: 'arrow_circle_down',
    color: '#f59e0b',
    displayOrder: 3,
  ),
  AccountGroupSeed(
    id: '1200',
    classId: 1,
    technicalName: 'Inversiones',
    friendlyName: 'Inversiones (CDT, Acciones, Cripto)',
    nature: AccountNature.DEBIT,
    icon: 'trending_up',
    color: '#8b5cf6',
    displayOrder: 4,
  ),
  AccountGroupSeed(
    id: '1524',
    classId: 1,
    technicalName: 'Equipo de Oficina',
    friendlyName: 'Computadores y Equipos',
    nature: AccountNature.DEBIT,
    icon: 'computer',
    color: '#64748b',
    displayOrder: 5,
  ),
  AccountGroupSeed(
    id: '1540',
    classId: 1,
    technicalName: 'Flota y Equipo de Transporte',
    friendlyName: 'Vehículos (Carro, Moto)',
    nature: AccountNature.DEBIT,
    icon: 'directions_car',
    color: '#ef4444',
    displayOrder: 6,
  ),
  AccountGroupSeed(
    id: '1516',
    classId: 1,
    technicalName: 'Construcciones y Edificaciones',
    friendlyName: 'Casas y Propiedades',
    nature: AccountNature.DEBIT,
    icon: 'home',
    color: '#f97316',
    displayOrder: 7,
  ),

  // ========================================================================
  // CLASS 2: PASIVOS (Lo que Debo)
  // ========================================================================

  AccountGroupSeed(
    id: '2105',
    classId: 2,
    technicalName: 'Bancos Nacionales',
    friendlyName: 'Tarjetas de Crédito',
    nature: AccountNature.CREDIT,
    icon: 'credit_card',
    color: '#dc2626',
    displayOrder: 1,
  ),
  AccountGroupSeed(
    id: '2120',
    classId: 2,
    technicalName: 'Obligaciones Financieras',
    friendlyName: 'Préstamos Bancarios',
    nature: AccountNature.CREDIT,
    icon: 'account_balance',
    color: '#b91c1c',
    displayOrder: 2,
  ),
  AccountGroupSeed(
    id: '2335',
    classId: 2,
    technicalName: 'Costos y Gastos por Pagar',
    friendlyName: 'Cuentas por Pagar',
    nature: AccountNature.CREDIT,
    icon: 'receipt_long',
    color: '#ea580c',
    displayOrder: 3,
  ),
  AccountGroupSeed(
    id: '2380',
    classId: 2,
    technicalName: 'Acreedores Varios',
    friendlyName: 'Deudas con Personas',
    nature: AccountNature.CREDIT,
    icon: 'people',
    color: '#f59e0b',
    displayOrder: 4,
  ),
  AccountGroupSeed(
    id: '2365',
    classId: 2,
    technicalName: 'Retención en la Fuente',
    friendlyName: 'Impuestos por Pagar',
    nature: AccountNature.CREDIT,
    icon: 'receipt',
    color: '#d97706',
    displayOrder: 5,
  ),

  // ========================================================================
  // CLASS 3: PATRIMONIO (Mis Ahorros Netos)
  // ========================================================================

  AccountGroupSeed(
    id: '3105',
    classId: 3,
    technicalName: 'Capital Suscrito y Pagado',
    friendlyName: 'Capital Inicial',
    nature: AccountNature.CREDIT,
    icon: 'savings',
    color: '#0891b2',
    displayOrder: 1,
  ),
  AccountGroupSeed(
    id: '3605',
    classId: 3,
    technicalName: 'Utilidades del Ejercicio',
    friendlyName: 'Ganancia del Mes',
    nature: AccountNature.CREDIT,
    icon: 'trending_up',
    color: '#14b8a6',
    displayOrder: 2,
  ),
  AccountGroupSeed(
    id: '3705',
    classId: 3,
    technicalName: 'Pérdidas del Ejercicio',
    friendlyName: 'Pérdida del Mes',
    nature: AccountNature.DEBIT,
    icon: 'trending_down',
    color: '#ef4444',
    displayOrder: 3,
  ),

  // ========================================================================
  // CLASS 4: INGRESOS (Dinero que Recibo)
  // ========================================================================

  AccountGroupSeed(
    id: '4100',
    classId: 4,
    technicalName: 'Operacionales - Actividades Ordinarias',
    friendlyName: 'Ingresos Laborales',
    nature: AccountNature.CREDIT,
    icon: 'work',
    color: '#22c55e',
    displayOrder: 1,
  ),
  AccountGroupSeed(
    id: '4135',
    classId: 4,
    technicalName: 'Comercio al por Mayor y al por Menor',
    friendlyName: 'Ingresos por Ventas',
    nature: AccountNature.CREDIT,
    icon: 'storefront',
    color: '#16a34a',
    displayOrder: 2,
  ),
  AccountGroupSeed(
    id: '4175',
    classId: 4,
    technicalName: 'Devoluciones en Ventas',
    friendlyName: 'Devoluciones',
    nature: AccountNature.DEBIT,
    icon: 'undo',
    color: '#ef4444',
    displayOrder: 3,
  ),
  AccountGroupSeed(
    id: '4200',
    classId: 4,
    technicalName: 'No Operacionales',
    friendlyName: 'Otros Ingresos',
    nature: AccountNature.CREDIT,
    icon: 'add_circle',
    color: '#059669',
    displayOrder: 4,
  ),
  AccountGroupSeed(
    id: '4210',
    classId: 4,
    technicalName: 'Financieros',
    friendlyName: 'Rendimientos Financieros',
    nature: AccountNature.CREDIT,
    icon: 'account_balance',
    color: '#10b981',
    displayOrder: 5,
  ),
  AccountGroupSeed(
    id: '4220',
    classId: 4,
    technicalName: 'Arrendamientos',
    friendlyName: 'Ingresos por Arriendos',
    nature: AccountNature.CREDIT,
    icon: 'home_work',
    color: '#14b8a6',
    displayOrder: 6,
  ),

  // ========================================================================
  // CLASS 5: GASTOS (Dinero que Pago)
  // ========================================================================

  // ---- GASTOS FIJOS (5100 - 5299) ----

  AccountGroupSeed(
    id: '5100',
    classId: 5,
    technicalName: 'Gastos Operacionales de Administración',
    friendlyName: 'Gastos Fijos - Vivienda',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'home',
    color: '#3b82f6',
    displayOrder: 1,
  ),
  AccountGroupSeed(
    id: '5110',
    classId: 5,
    technicalName: 'Gastos de Personal',
    friendlyName: 'Gastos Fijos - Empleados',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'people',
    color: '#6366f1',
    displayOrder: 2,
  ),
  AccountGroupSeed(
    id: '5135',
    classId: 5,
    technicalName: 'Servicios',
    friendlyName: 'Gastos Fijos - Servicios Públicos',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'power',
    color: '#8b5cf6',
    displayOrder: 3,
  ),
  AccountGroupSeed(
    id: '5140',
    classId: 5,
    technicalName: 'Gastos Legales',
    friendlyName: 'Gastos Fijos - Legales y Notariales',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'gavel',
    color: '#a855f7',
    displayOrder: 4,
  ),
  AccountGroupSeed(
    id: '5145',
    classId: 5,
    technicalName: 'Mantenimiento y Reparaciones',
    friendlyName: 'Gastos Fijos - Mantenimiento',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'build',
    color: '#c084fc',
    displayOrder: 5,
  ),
  AccountGroupSeed(
    id: '5150',
    classId: 5,
    technicalName: 'Adecuación e Instalación',
    friendlyName: 'Gastos Fijos - Adecuaciones',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'construction',
    color: '#d946ef',
    displayOrder: 6,
  ),
  AccountGroupSeed(
    id: '5160',
    classId: 5,
    technicalName: 'Seguros',
    friendlyName: 'Gastos Fijos - Seguros',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'shield',
    color: '#0891b2',
    displayOrder: 7,
  ),
  AccountGroupSeed(
    id: '5195',
    classId: 5,
    technicalName: 'Diversos',
    friendlyName: 'Gastos Fijos - Otros',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.FIXED,
    icon: 'more_horiz',
    color: '#06b6d4',
    displayOrder: 8,
  ),

  // ---- GASTOS VARIABLES (5300 - 5599) ----

  AccountGroupSeed(
    id: '5300',
    classId: 5,
    technicalName: 'Gastos de Ventas',
    friendlyName: 'Gastos Variables - Ventas',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'point_of_sale',
    color: '#f59e0b',
    displayOrder: 9,
  ),
  AccountGroupSeed(
    id: '5305',
    classId: 5,
    technicalName: 'Gastos de Personal de Ventas',
    friendlyName: 'Gastos Variables - Comisiones',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'payments',
    color: '#f97316',
    displayOrder: 10,
  ),
  AccountGroupSeed(
    id: '5400',
    classId: 5,
    technicalName: 'No Operacionales',
    friendlyName: 'Gastos Variables - Personales',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'person',
    color: '#ef4444',
    displayOrder: 11,
  ),
  AccountGroupSeed(
    id: '5405',
    classId: 5,
    technicalName: 'Gastos Financieros',
    friendlyName: 'Gastos Variables - Intereses',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'trending_down',
    color: '#dc2626',
    displayOrder: 12,
  ),
  AccountGroupSeed(
    id: '5410',
    classId: 5,
    technicalName: 'Pérdida en Venta y Retiro de Bienes',
    friendlyName: 'Gastos Variables - Pérdidas',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'trending_down',
    color: '#b91c1c',
    displayOrder: 13,
  ),
  AccountGroupSeed(
    id: '5415',
    classId: 5,
    technicalName: 'Gastos Extraordinarios',
    friendlyName: 'Gastos Variables - Extraordinarios',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'new_releases',
    color: '#a21caf',
    displayOrder: 14,
  ),

  // ---- COSTO DE VENTAS (Gastos operacionales directos) ----

  AccountGroupSeed(
    id: '6100',
    classId: 5,
    technicalName: 'Costo de Ventas',
    friendlyName: 'Costo de Productos Vendidos',
    nature: AccountNature.DEBIT,
    expenseType: ExpenseType.VARIABLE,
    icon: 'inventory',
    color: '#ea580c',
    displayOrder: 15,
  ),
];

/// Clase auxiliar para semilla de AccountClasses
class AccountClassSeed {
  final int id;
  final String name;
  final String presentationName;
  final String description;
  final int displayOrder;

  const AccountClassSeed({
    required this.id,
    required this.name,
    required this.presentationName,
    required this.description,
    required this.displayOrder,
  });
}

/// Clase auxiliar para semilla de AccountGroups
class AccountGroupSeed {
  final String id;
  final int classId;
  final String technicalName;
  final String friendlyName;
  final AccountNature nature;
  final ExpenseType? expenseType;
  final String? icon;
  final String? color;
  final int displayOrder;

  const AccountGroupSeed({
    required this.id,
    required this.classId,
    required this.technicalName,
    required this.friendlyName,
    required this.nature,
    this.expenseType,
    this.icon,
    this.color,
    required this.displayOrder,
  });
}
