// test/helpers/test_helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/add_transaction_sheet.dart';

/// TestMainScaffold que replica la funcionalidad del MainScaffold real
/// Mantiene BottomNavigationBar para compatibilidad con tests existentes
/// pero agrega la funcionalidad del FAB para mostrar el selector de transacciones
class TestMainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int>? onNavigationTap;

  const TestMainScaffold({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.onNavigationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nueva transacción',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _TransactionTypeButton(
                      icon: Icons.arrow_downward,
                      label: 'Gasto',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _openTransactionForm(context, TransactionType.expense);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TransactionTypeButton(
                      icon: Icons.arrow_upward,
                      label: 'Ingreso',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _openTransactionForm(context, TransactionType.income);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TransactionTypeButton(
                      icon: Icons.swap_horiz,
                      label: 'Transferencia',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _openTransactionForm(context, TransactionType.transfer);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openTransactionForm(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: AddTransactionSheet(initialType: type),
      ),
    );
  }
}

class _TransactionTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TransactionTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helpers genericos para tests
class TestHelpers {
  /// Genera datos de prueba segun el tipo especificado
  static Map<String, dynamic> generarDatosPrueba({
    required String tipo,
    Map<String, dynamic>? overrides,
  }) {
    final base = _datosBase(tipo);
    if (overrides != null) {
      base.addAll(overrides);
    }
    return base;
  }

  static Map<String, dynamic> _datosBase(String tipo) {
    switch (tipo) {
      case 'cuenta':
        return {
          'id': 'cuenta_test_${DateTime.now().millisecondsSinceEpoch}',
          'nombre': 'Cuenta Test',
          'tipo': 'banco',
          'saldo': 1000000.0,
          'moneda': 'COP',
        };
      case 'transaccion':
        return {
          'id': 'trans_test_${DateTime.now().millisecondsSinceEpoch}',
          'tipo': 'gasto',
          'monto': 50000.0,
          'fecha': DateTime.now(),
          'descripcion': 'Transaccion test',
        };
      case 'categoria':
        return {
          'id': 'cat_test_${DateTime.now().millisecondsSinceEpoch}',
          'nombre': 'Categoria Test',
          'tipo': 'gasto',
        };
      case 'presupuesto':
        return {
          'id': 'pres_test_${DateTime.now().millisecondsSinceEpoch}',
          'montoPlaneado': 500000.0,
          'montoGastado': 0.0,
        };
      case 'meta':
        return {
          'id': 'meta_test_${DateTime.now().millisecondsSinceEpoch}',
          'nombre': 'Meta Test',
          'montoObjetivo': 1000000.0,
          'montoActual': 0.0,
        };
      default:
        return {'id': 'unknown_${DateTime.now().millisecondsSinceEpoch}'};
    }
  }
}

/// Builder para crear datos de test complejos
class TestDataBuilder {
  Map<String, dynamic> _usuario = {};
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _transacciones = [];
  List<Map<String, dynamic>> _presupuestos = [];
  List<Map<String, dynamic>> _metas = [];

  TestDataBuilder conUsuario(Map<String, dynamic> usuario) {
    _usuario = usuario;
    return this;
  }

  TestDataBuilder conCuentas(List<Map<String, dynamic>> cuentas) {
    _cuentas = cuentas;
    return this;
  }

  TestDataBuilder conTransacciones(List<Map<String, dynamic>> transacciones) {
    _transacciones = transacciones;
    return this;
  }

  TestDataBuilder conPresupuestos(List<Map<String, dynamic>> presupuestos) {
    _presupuestos = presupuestos;
    return this;
  }

  TestDataBuilder conMetas(List<Map<String, dynamic>> metas) {
    _metas = metas;
    return this;
  }

  Map<String, dynamic> build() {
    return {
      'usuario': _usuario,
      'cuentas': _cuentas,
      'transacciones': _transacciones,
      'presupuestos': _presupuestos,
      'metas': _metas,
    };
  }
}

/// Simulador de tiempo para tests
class TimeSimulator {
  DateTime _currentTime;

  TimeSimulator([DateTime? startTime])
      : _currentTime = startTime ?? DateTime.now();

  DateTime get now => _currentTime;

  void avanzarDias(int dias) {
    _currentTime = _currentTime.add(Duration(days: dias));
  }

  void avanzarHoras(int horas) {
    _currentTime = _currentTime.add(Duration(hours: horas));
  }

  void irAFecha(DateTime fecha) {
    _currentTime = fecha;
  }

  /// Alias de irAFecha para compatibilidad
  void establecer(DateTime fecha) {
    _currentTime = fecha;
  }
}

// ============================================
// FUNCIONES HELPER PARA CALCULOS
// ============================================

/// Suma los saldos de una lista de cuentas
double sumarSaldos(List<Map<String, dynamic>> cuentas) {
  return cuentas.fold(0.0, (sum, cuenta) => sum + (cuenta['saldo'] as num).toDouble());
}

/// Suma los montos planeados de una lista de presupuestos
double sumarPresupuestos(List<Map<String, dynamic>> presupuestos) {
  return presupuestos.fold(
      0.0, (sum, p) => sum + (p['montoPlaneado'] as num).toDouble());
}

/// Suma los montos de una lista de transacciones
double sumarTransacciones(List<Map<String, dynamic>> transacciones) {
  return transacciones.fold(0.0, (sum, t) => sum + (t['monto'] as num).toDouble());
}

/// Filtra transacciones por tipo
List<Map<String, dynamic>> filtrarPorTipo(
    List<Map<String, dynamic>> transacciones, String tipo) {
  return transacciones.where((t) => t['tipo'] == tipo).toList();
}

// ============================================
// HELPERS PARA TESTS COMBINATORIALES
// ============================================

/// Obtiene el monto gastado segun el estado del presupuesto
double obtenerMontoSegunEstado(String estado, {double montoPlaneado = 500000}) {
  switch (estado) {
    case 'normal':
      return montoPlaneado * 0.6; // 60%
    case 'cerca_limite':
      return montoPlaneado * 0.9; // 90%
    case 'excedido':
      return montoPlaneado * 1.1; // 110%
    default:
      return 0;
  }
}

/// Valida si una combinacion de transaccion/cuenta/categoria es valida
bool validarCombinacion(String tipoTrans, String tipoCuenta, String categoria) {
  if (tipoTrans == 'ingreso' &&
      ['alimentacion', 'transporte'].contains(categoria)) {
    return false;
  }
  if (tipoTrans == 'gasto' && ['salario', 'ventas'].contains(categoria)) {
    return false;
  }
  return true;
}

/// Calcula el numero de ejecuciones de una transaccion recurrente
/// Nota: Siempre retorna al menos 1 para la primera ejecución
int calcularEjecuciones(String frecuencia, int dia, int duracion) {
  int result;
  switch (frecuencia) {
    case 'diaria':
      result = duracion;
      break;
    case 'semanal':
      result = (duracion / 7).floor();
      break;
    case 'quincenal':
      result = (duracion / 15).floor();
      break;
    case 'mensual':
      result = (duracion / 30).floor();
      break;
    case 'anual':
      result = (duracion / 365).floor();
      break;
    default:
      return 0;
  }
  // Siempre hay al menos 1 ejecución si la duración es positiva
  return result > 0 ? result : (duracion > 0 ? 1 : 0);
}

/// Verifica compatibilidad entre dos features
bool verificarCompatibilidad(String featureA, String featureB) {
  final compatibilidades = {
    'cuentas': ['transacciones', 'metas', 'reportes'],
    'transacciones': ['cuentas', 'presupuestos', 'metas', 'reportes'],
    'presupuestos': ['transacciones', 'alertas', 'reportes'],
    'metas': ['cuentas', 'transacciones', 'notificaciones', 'reportes'],
    'reportes': ['cuentas', 'transacciones', 'presupuestos', 'metas'],
    'alertas': ['presupuestos', 'notificaciones'],
    'notificaciones': ['metas', 'alertas'],
  };

  return compatibilidades[featureA]?.contains(featureB) ?? false;
}

// ============================================
// HELPERS PARA SETUP DE TESTS
// ============================================

/// Setup completo del ambiente de testing
Future<void> setupFullTestEnvironment() async {
  // Inicializar localización para DateFormat (español)
  await initializeDateFormatting('es', null);

  // Habilitar modo test de Supabase para evitar llamadas reales
  SupabaseClientProvider.enableTestMode();
}

/// Alias para setupFullTestEnvironment (usado en E2E tests)
Future<void> setupTestEnvironment() async {
  // Inicializar localización para DateFormat (español)
  await initializeDateFormatting('es', null);

  // Habilitar modo test de Supabase
  SupabaseClientProvider.enableTestMode();
}

/// Teardown del ambiente de testing
Future<void> tearDownTestEnvironment() async {
  // Resetear el provider de Supabase
  SupabaseClientProvider.reset();
}

/// Crear database de prueba
dynamic createTestDatabase() {
  // Retorna una instancia mock o in-memory de la DB
  // En tests reales, esto deberia crear AppDatabase.inMemory()
  return null; // Placeholder
}
