import 'package:flutter/foundation.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/accounts_dao.dart';
import '../../data/local/daos/categories_dao.dart';
import '../../data/local/seeders/accounts_seeder.dart';
import '../../data/local/seeders/category_seeder.dart';
// NOTA: accounts_seeder ya no depende de CategoriesDao
// Usa UUIDs determinísticos para categoryId

/// Servicio para sembrar datos iniciales
///
/// Este servicio verifica si hay datos existentes (posiblemente sincronizados desde
/// Supabase) antes de sembrar. SOLO siembra si la base de datos está vacía.
///
/// Orden de operaciones para recuperación de datos post-reinstalación:
/// 1. Usuario se autentica (OAuth o email/password)
/// 2. PowerSync sincroniza datos desde Supabase
/// 3. Este servicio verifica si hay datos
/// 4. Solo si está vacío, siembra datos predefinidos
class DataSeedingService {
  final AppDatabase _db;

  DataSeedingService(this._db);

  /// Ejecuta el seeding si es necesario
  /// Retorna true si se sembraron datos, false si ya había datos
  Future<bool> seedIfEmpty() async {
    debugPrint('[SEEDING] Verificando si se necesita sembrar datos...');

    final categoriesDao = CategoriesDao(_db);
    final accountsDao = AccountsDao(_db);

    final existingCategories = await categoriesDao.getAllCategories();
    final existingAccounts = await accountsDao.getAllAccounts();

    debugPrint('[SEEDING] Categorías existentes: ${existingCategories.length}');
    debugPrint('[SEEDING] Cuentas existentes: ${existingAccounts.length}');

    bool seeded = false;

    // Sembrar categorías si no existen
    if (existingCategories.isEmpty) {
      debugPrint('[SEEDING] Sembrando categorías...');
      await seedCategories(categoriesDao);
      debugPrint('[SEEDING] Categorías sembradas');
      seeded = true;
    }

    // Sembrar cuentas si no existen (incluso si las categorías ya existían)
    if (existingAccounts.isEmpty) {
      debugPrint('[SEEDING] Sembrando cuentas...');
      // Ya no depende de categorías: usa UUIDs determinísticos
      await seedAccounts(accountsDao);
      debugPrint('[SEEDING] Cuentas sembradas');
      seeded = true;
    }

    if (!seeded) {
      debugPrint('[SEEDING] No se necesitó sembrar datos');
    }

    return seeded;
  }

  /// Verifica si la base de datos tiene datos del usuario
  Future<bool> hasUserData() async {
    final categoriesDao = CategoriesDao(_db);
    final existingCategories = await categoriesDao.getAllCategories();
    return existingCategories.isNotEmpty;
  }
}
