import '../../domain/services/financial_indicators_service.dart';
import '../local/daos/accounts_dao.dart';
import '../local/daos/categories_dao.dart';

/// Implementación Drift del repositorio para indicadores financieros
class DriftAccountDataRepository implements AccountDataRepository {
  final AccountsDao _accountsDao;
  final CategoriesDao _categoriesDao;

  DriftAccountDataRepository({
    required AccountsDao accountsDao,
    required CategoriesDao categoriesDao,
  })  : _accountsDao = accountsDao,
        _categoriesDao = categoriesDao;

  @override
  Future<List<AccountBalance>> getAllAccountBalances() async {
    final accounts = await _accountsDao.getActiveAccounts();
    return accounts
        .map((a) => AccountBalance(
              id: a.id,
              categoryId: a.categoryId,
              balance: a.balance ?? 0.0,
            ))
        .toList();
  }

  @override
  Future<List<CategoryInfo>> getCategoriesByType(String type) async {
    final categories = await _categoriesDao.getCategoriesByType(type);
    return categories
        .map((c) => CategoryInfo(
              id: c.id,
              name: c.name,
              type: c.type,
            ))
        .toList();
  }
}
