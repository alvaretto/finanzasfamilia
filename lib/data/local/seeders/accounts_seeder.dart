import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/accounts_dao.dart';
import '../daos/categories_dao.dart';

const _uuid = Uuid();

/// Siembra cuentas predefinidas basadas en el diagrama nuevo-mermaid2.md
/// Las cuentas corresponden a las hojas de "Lo que Tengo" (Activos)
Future<void> seedAccounts(AccountsDao accountsDao, CategoriesDao categoriesDao) async {
  final existingAccounts = await accountsDao.getAllAccounts();
  if (existingAccounts.isNotEmpty) {
    return; // Ya sembrado
  }

  final allCategories = await categoriesDao.getAllCategories();

  // Helper para buscar categoría por nombre
  CategoryEntry? findCategory(String name) {
    try {
      return allCategories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  final accounts = <AccountsCompanion>[];

  // ==========================================
  // EFECTIVO
  // ==========================================
  final billeteraPersonal = findCategory('Billetera Personal');
  if (billeteraPersonal != null) {
    accounts.add(_account(
      name: 'Billetera Personal',
      icon: '💵',
      categoryId: billeteraPersonal.id,
      color: '#4CAF50',
    ));
  }

  final cajaMenor = findCategory('Caja Menor Casa');
  if (cajaMenor != null) {
    accounts.add(_account(
      name: 'Caja Menor Casa',
      icon: '🏠',
      categoryId: cajaMenor.id,
      color: '#8BC34A',
    ));
  }

  final alcancia = findCategory('Alcancía / Ahorro Físico');
  if (alcancia != null) {
    accounts.add(_account(
      name: 'Alcancía',
      icon: '🐷',
      categoryId: alcancia.id,
      color: '#FF9800',
    ));
  }

  // ==========================================
  // BANCOS - CUENTA DE AHORROS
  // ==========================================
  final daviviendaCat = findCategory('Davivienda');
  if (daviviendaCat != null) {
    accounts.add(_account(
      name: 'Davivienda',
      icon: '🏦',
      categoryId: daviviendaCat.id,
      color: '#E53935',
    ));
  }

  final bancolombiaCat = findCategory('Bancolombia');
  if (bancolombiaCat != null) {
    accounts.add(_account(
      name: 'Bancolombia',
      icon: '🏦',
      categoryId: bancolombiaCat.id,
      color: '#FFCE00',
    ));
  }

  // ==========================================
  // BANCOS - BILLETERAS DIGITALES
  // ==========================================
  final daviplataCat = findCategory('DaviPlata');
  if (daviplataCat != null) {
    accounts.add(_account(
      name: 'DaviPlata',
      icon: '📱',
      categoryId: daviplataCat.id,
      color: '#E53935',
    ));
  }

  final nequiCat = findCategory('Nequi');
  if (nequiCat != null) {
    accounts.add(_account(
      name: 'Nequi',
      icon: '💜',
      categoryId: nequiCat.id,
      color: '#6B2D8B',
    ));
  }

  final dollarAppCat = findCategory('DollarApp');
  if (dollarAppCat != null) {
    accounts.add(_account(
      name: 'DollarApp',
      icon: '💲',
      categoryId: dollarAppCat.id,
      color: '#2196F3',
    ));
  }

  final paypalCat = findCategory('PayPal');
  if (paypalCat != null) {
    accounts.add(_account(
      name: 'PayPal',
      icon: '🅿️',
      categoryId: paypalCat.id,
      color: '#003087',
    ));
  }

  // ==========================================
  // INVERSIONES
  // ==========================================
  final cdtCat = findCategory('CDT / Fiducias');
  if (cdtCat != null) {
    accounts.add(_account(
      name: 'CDT / Fiducias',
      icon: '📈',
      categoryId: cdtCat.id,
      color: '#009688',
      includeInTotal: false, // No incluir en balance diario
    ));
  }

  final propiedadesCat = findCategory('Propiedades');
  if (propiedadesCat != null) {
    accounts.add(_account(
      name: 'Propiedades',
      icon: '🏘️',
      categoryId: propiedadesCat.id,
      color: '#795548',
      includeInTotal: false, // No incluir en balance diario
    ));
  }

  // Insertar cuentas
  for (final account in accounts) {
    await accountsDao.insertAccount(account);
  }
}

/// Helper para crear una cuenta
AccountsCompanion _account({
  required String name,
  required String icon,
  required String categoryId,
  required String color,
  bool includeInTotal = true,
}) {
  return AccountsCompanion.insert(
    id: _uuid.v4(),
    name: name,
    icon: Value(icon),
    categoryId: categoryId,
    balance: const Value(0.0),
    color: Value(color),
    includeInTotal: Value(includeInTotal),
  );
}
