import '../../features/transactions/domain/models/transaction_model.dart';
import '../utils/budget_50_30_20.dart';

/// Servicio para calcular la distribución 50/30/20 del presupuesto
class Budget503020Service {
  /// Calcula el presupuesto 50/30/20 basado en las transacciones del mes
  static Budget503020 calculate({
    required List<TransactionModel> transactions,
    required double monthlyIncome,
  }) {
    double necessitiesSpent = 0;
    double wantsSpent = 0;

    // Clasificar gastos por categoría
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;

      final categoryName = tx.categoryName?.toLowerCase() ?? '';

      if (_isNecessity(categoryName)) {
        necessitiesSpent += tx.amount;
      } else {
        wantsSpent += tx.amount;
      }
    }

    // Calcular ahorros (ingresos - gastos totales)
    final totalExpenses = necessitiesSpent + wantsSpent;
    final savings = monthlyIncome - totalExpenses;

    return Budget503020(
      monthlyIncome: monthlyIncome,
      necessitiesSpent: necessitiesSpent,
      wantsSpent: wantsSpent,
      savings: savings,
    );
  }

  /// Determina si una categoría es una "necesidad" según la regla 50/30/20
  ///
  /// Necesidades (50%):
  /// - Vivienda (renta, servicios básicos)
  /// - Alimentación básica (supermercado, no restaurantes)
  /// - Transporte (combustible, transporte público)
  /// - Salud (medicina, consultas médicas)
  /// - Servicios financieros básicos
  /// - Impuestos
  static bool _isNecessity(String categoryName) {
    // Vivienda - TODO
    if (categoryName.contains('vivienda') ||
        categoryName.contains('renta') ||
        categoryName.contains('hipoteca') ||
        categoryName.contains('administracion') ||
        categoryName.contains('agua') ||
        categoryName.contains('energia') ||
        categoryName.contains('gas') ||
        categoryName.contains('internet') ||
        categoryName.contains('telefono')) {
      return true;
    }

    // Alimentación básica (solo supermercado)
    if (categoryName.contains('supermercado')) {
      return true;
    }

    // Transporte
    if (categoryName.contains('transporte') ||
        categoryName.contains('combustible') ||
        categoryName.contains('publico') ||
        categoryName.contains('parqueadero')) {
      return true;
    }

    // Salud
    if (categoryName.contains('salud') ||
        categoryName.contains('medicina') ||
        categoryName.contains('consulta') ||
        categoryName.contains('medicamento') ||
        categoryName.contains('odontologia') ||
        categoryName.contains('eps')) {
      return true;
    }

    // Servicios financieros básicos
    if (categoryName.contains('cuota manejo') ||
        categoryName.contains('comision') ||
        categoryName.contains('seguro')) {
      return true;
    }

    // Impuestos
    if (categoryName.contains('impuesto') ||
        categoryName.contains('predial')) {
      return true;
    }

    return false;
  }

  /// Determina si una categoría es un "gusto" según la regla 50/30/20
  ///
  /// Gustos (30%):
  /// - Entretenimiento
  /// - Restaurantes y delivery
  /// - Ropa y calzado
  /// - Tecnología (no esencial)
  /// - Mascotas
  /// - Bienestar (gimnasio, spa)
  static bool _isWant(String categoryName) {
    // Entretenimiento
    if (categoryName.contains('entretenimiento') ||
        categoryName.contains('streaming') ||
        categoryName.contains('cine') ||
        categoryName.contains('teatro') ||
        categoryName.contains('evento') ||
        categoryName.contains('videojuego') ||
        categoryName.contains('hobby') ||
        categoryName.contains('vacacion') ||
        categoryName.contains('viaje')) {
      return true;
    }

    // Alimentación no esencial
    if (categoryName.contains('restaurante') ||
        categoryName.contains('delivery') ||
        categoryName.contains('cafeteria') ||
        categoryName.contains('licor')) {
      return true;
    }

    // Ropa y calzado
    if (categoryName.contains('ropa') ||
        categoryName.contains('calzado') ||
        categoryName.contains('accesorio')) {
      return true;
    }

    // Tecnología (no esencial)
    if (categoryName.contains('tecnologia') ||
        categoryName.contains('celular') ||
        categoryName.contains('hardware') ||
        categoryName.contains('software')) {
      return true;
    }

    // Mascotas
    if (categoryName.contains('mascota') ||
        categoryName.contains('veterinario')) {
      return true;
    }

    // Bienestar (no médico)
    if (categoryName.contains('gimnasio') ||
        categoryName.contains('deporte') ||
        categoryName.contains('spa') ||
        categoryName.contains('cuidado personal') ||
        categoryName.contains('cosmetico')) {
      return true;
    }

    return false;
  }
}
