// Excepciones de dominio para operaciones contables.
// Permiten manejar errores de negocio de forma tipada.

/// Error cuando se intenta gastar más de lo disponible en una cuenta líquida.
class InsufficientFundsException implements Exception {
  final double available;
  final double required;
  final String accountName;

  const InsufficientFundsException({
    required this.available,
    required this.required,
    required this.accountName,
  });

  double get shortfall => required - available;

  @override
  String toString() =>
      'Fondos insuficientes en $accountName: disponible \$${available.toStringAsFixed(0)}, '
      'requerido \$${required.toStringAsFixed(0)} (faltan \$${shortfall.toStringAsFixed(0)})';
}

/// Error cuando se intenta eliminar una cuenta que tiene saldo.
class AccountHasBalanceException implements Exception {
  final double balance;
  final String accountName;

  const AccountHasBalanceException({
    required this.balance,
    required this.accountName,
  });

  @override
  String toString() =>
      'No se puede eliminar "$accountName": tiene saldo de \$${balance.toStringAsFixed(0)}. '
      'Transfiere o ajusta el saldo antes de eliminar.';
}

/// Error cuando se intenta eliminar una categoría que tiene hijos.
class CategoryHasChildrenException implements Exception {
  final String categoryName;
  final int childCount;

  const CategoryHasChildrenException({
    required this.categoryName,
    required this.childCount,
  });

  @override
  String toString() =>
      'No se puede eliminar "$categoryName": tiene $childCount subcategoría(s). '
      'Elimina primero las subcategorías.';
}

/// Error cuando se intenta eliminar una categoría del sistema.
class SystemCategoryException implements Exception {
  final String categoryName;

  const SystemCategoryException({required this.categoryName});

  @override
  String toString() =>
      'No se puede eliminar "$categoryName": es una categoría del sistema.';
}
