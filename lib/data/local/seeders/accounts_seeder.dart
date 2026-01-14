import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/accounts_dao.dart';

const _uuid = Uuid();

/// Namespace UUID para generar IDs determinísticos de cuentas del sistema.
/// Esto asegura que las mismas cuentas tengan los mismos IDs en cualquier
/// instalación, permitiendo sincronización correcta con PowerSync.
const _systemAccountNamespace = '550e8400-e29b-41d4-a716-446655440000';

/// Namespace UUID para categorías (DEBE coincidir con category_seeder.dart)
/// Usado para calcular categoryId determinístico sin depender de consultas locales.
const _systemCategoryNamespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

/// Genera un UUID determinístico para una cuenta del sistema.
/// Usa UUID v5 (basado en SHA-1) con el namespace y el nombre de la cuenta.
String _deterministicAccountId(String accountName) {
  return _uuid.v5(_systemAccountNamespace, 'account:$accountName');
}

/// Genera un UUID determinístico para una categoría del sistema.
/// DEBE usar la misma lógica que category_seeder.dart para que los IDs coincidan.
String _deterministicCategoryId(String categoryName, String type) {
  return _uuid.v5(_systemCategoryNamespace, '$type:$categoryName');
}

/// Siembra cuentas predefinidas basadas en el diagrama nuevo-mermaid2.md
/// Las cuentas corresponden a las hojas de "Lo que Tengo" (Activos)
///
/// IMPORTANTE: Usa UUIDs determinísticos tanto para accounts como para categoryId.
/// Esto garantiza que PowerSync pueda sincronizar correctamente sin FK violations.
Future<void> seedAccounts(AccountsDao accountsDao) async {
  final existingAccounts = await accountsDao.getAllAccounts();
  if (existingAccounts.isNotEmpty) {
    return; // Ya sembrado
  }

  final accounts = <AccountsCompanion>[
    // ==========================================
    // EFECTIVO (type: asset)
    // ==========================================
    _account(
      name: 'Billetera Personal',
      icon: '💵',
      categoryId: _deterministicCategoryId('Billetera Personal', 'asset'),
      color: '#4CAF50',
    ),
    _account(
      name: 'Caja Menor Casa',
      icon: '🏠',
      categoryId: _deterministicCategoryId('Caja Menor Casa', 'asset'),
      color: '#8BC34A',
    ),
    _account(
      name: 'Alcancía',
      icon: '🐷',
      categoryId: _deterministicCategoryId('Alcancía / Ahorro Físico', 'asset'),
      color: '#FF9800',
    ),

    // ==========================================
    // BANCOS - CUENTA DE AHORROS (type: asset)
    // ==========================================
    _account(
      name: 'Davivienda',
      icon: '🏦',
      categoryId: _deterministicCategoryId('Davivienda', 'asset'),
      color: '#E53935',
    ),
    _account(
      name: 'Bancolombia',
      icon: '🏦',
      categoryId: _deterministicCategoryId('Bancolombia', 'asset'),
      color: '#FFCE00',
    ),

    // ==========================================
    // BANCOS - BILLETERAS DIGITALES (type: asset)
    // ==========================================
    _account(
      name: 'DaviPlata',
      icon: '📱',
      categoryId: _deterministicCategoryId('DaviPlata', 'asset'),
      color: '#E53935',
    ),
    _account(
      name: 'Nequi',
      icon: '💜',
      categoryId: _deterministicCategoryId('Nequi', 'asset'),
      color: '#6B2D8B',
    ),
    _account(
      name: 'DollarApp',
      icon: '💲',
      categoryId: _deterministicCategoryId('DollarApp', 'asset'),
      color: '#2196F3',
    ),
    _account(
      name: 'PayPal',
      icon: '🅿️',
      categoryId: _deterministicCategoryId('PayPal', 'asset'),
      color: '#003087',
    ),

    // ==========================================
    // INVERSIONES (type: asset)
    // ==========================================
    _account(
      name: 'CDT / Fiducias',
      icon: '📈',
      categoryId: _deterministicCategoryId('CDT / Fiducias', 'asset'),
      color: '#009688',
      includeInTotal: false, // No incluir en balance diario
    ),
    _account(
      name: 'Propiedades',
      icon: '🏘️',
      categoryId: _deterministicCategoryId('Propiedades', 'asset'),
      color: '#795548',
      includeInTotal: false, // No incluir en balance diario
    ),
  ];

  // Insertar cuentas
  for (final account in accounts) {
    await accountsDao.insertAccount(account);
  }
}

/// Helper para crear una cuenta del sistema (no eliminable)
/// IMPORTANTE: currency y type deben ser explícitos porque PowerSync no soporta defaults
///
/// Usa UUIDs determinísticos para que las mismas cuentas tengan los mismos IDs
/// en cualquier instalación, permitiendo sincronización correcta con PowerSync.
AccountsCompanion _account({
  required String name,
  required String icon,
  required String categoryId,
  required String color,
  bool includeInTotal = true,
  String currency = 'COP',
  String type = 'wallet', // Default: wallet (billetera)
}) {
  return AccountsCompanion.insert(
    id: _deterministicAccountId(name),
    name: name,
    type: Value(type), // Explícito: Supabase requiere este campo
    icon: Value(icon),
    categoryId: categoryId,
    balance: const Value(0.0),
    currency: Value(currency), // Explícito: PowerSync no usa defaults de Drift
    color: Value(color),
    includeInTotal: Value(includeInTotal),
    isActive: const Value(true), // Explícito
    isSystem: const Value(true), // Cuentas predefinidas no son eliminables
  );
}
