// test/helpers/test_helpers.dart

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
  // Placeholder - configurar ambiente de test
  // Puede incluir: inicializar mocks, limpiar DB, etc.
}

/// Crear database de prueba
dynamic createTestDatabase() {
  // Retorna una instancia mock o in-memory de la DB
  // En tests reales, esto deberia crear AppDatabase.inMemory()
  return null; // Placeholder
}
