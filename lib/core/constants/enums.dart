/// Tipos de cuenta principales (ramas del árbol financiero)
enum AccountType {
  /// Lo que Tengo (Activos)
  asset,

  /// Lo que Debo (Pasivos)
  liability,

  /// Dinero que Entra (Ingresos)
  income,

  /// Dinero que Sale (Gastos)
  expense,
}

/// Tipos de transacción
enum TransactionType {
  /// Ingreso de dinero
  income,

  /// Gasto de dinero
  expense,

  /// Transferencia entre cuentas
  transfer,
}

/// Estado de sincronización
enum SyncStatus {
  /// Pendiente de sincronizar
  pending,

  /// Sincronizado con el servidor
  synced,

  /// Error en sincronización
  error,
}
