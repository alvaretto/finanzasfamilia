/// Modelo para balance total de todas las cuentas.
/// Representa un resumen del patrimonio neto.
class TotalBalance {
  final double assets;
  final double liabilities;
  final double netWorth;
  final int accountCount;

  const TotalBalance({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.accountCount,
  });

  /// Balance neto (alias para netWorth)
  double get balance => netWorth;

  /// Crea un TotalBalance vacío
  factory TotalBalance.empty() {
    return const TotalBalance(
      assets: 0,
      liabilities: 0,
      netWorth: 0,
      accountCount: 0,
    );
  }
}
