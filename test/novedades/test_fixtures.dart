// test/fixtures/test_fixtures.dart

import 'package:flutter_test/flutter_test.dart';

/// Fixtures de datos predefinidos para tests
class TestFixtures {
  
  // ============================================
  // USUARIOS DE PRUEBA
  // ============================================
  
  static Map<String, dynamic> usuarioBas ico() => {
    'id': 'user_001',
    'nombre': 'María González',
    'email': 'maria@test.com',
    'ingresosMensuales': 3000000,
    'createdAt': DateTime(2025, 1, 1),
  };
  
  static Map<String, dynamic> usuarioAltos Ingresos() => {
    'id': 'user_002',
    'nombre': 'Carlos Rodríguez',
    'email': 'carlos@test.com',
    'ingresosMensuales': 10000000,
    'createdAt': DateTime(2025, 1, 1),
  };
  
  static Map<String, dynamic> usuarioIndependiente() => {
    'id': 'user_003',
    'nombre': 'Ana López',
    'email': 'ana@test.com',
    'ingresosMensuales': 2500000, // Variable
    'createdAt': DateTime(2025, 1, 1),
  };
  
  // ============================================
  // CUENTAS DE PRUEBA
  // ============================================
  
  static List<Map<String, dynamic>> cuentasBasicas() => [
    {
      'id': 'cuenta_001',
      'nombre': 'Bancolombia Ahorros',
      'tipo': 'banco',
      'saldo': 2500000,
      'moneda': 'COP',
      'emoji': '🏦',
    },
    {
      'id': 'cuenta_002',
      'nombre': 'Efectivo',
      'tipo': 'efectivo',
      'saldo': 200000,
      'moneda': 'COP',
      'emoji': '💵',
    },
    {
      'id': 'cuenta_003',
      'nombre': 'Nequi',
      'tipo': 'banco',
      'saldo': 150000,
      'moneda': 'COP',
      'emoji': '🏦',
    },
  ];
  
  // ============================================
  // CATEGORÍAS DE PRUEBA
  // ============================================
  
  static List<Map<String, dynamic>> categoriasGastos() => [
    {
      'id': 'cat_001',
      'nombre': 'Alimentación',
      'emoji': '🛒',
      'tipo': 'gasto',
      'tipoGasto': 'variable',
    },
    {
      'id': 'cat_002',
      'nombre': 'Transporte',
      'emoji': '🚗',
      'tipo': 'gasto',
      'tipoGasto': 'fijo',
    },
    {
      'id': 'cat_003',
      'nombre': 'Vivienda',
      'emoji': '🏠',
      'tipo': 'gasto',
      'tipoGasto': 'fijo',
    },
    {
      'id': 'cat_004',
      'nombre': 'Entretenimiento',
      'emoji': '🎮',
      'tipo': 'gasto',
      'tipoGasto': 'variable',
    },
    {
      'id': 'cat_005',
      'nombre': 'Salud',
      'emoji': '⚕️',
      'tipo': 'gasto',
      'tipoGasto': 'variable',
    },
  ];
  
  static List<Map<String, dynamic>> categoriasIngresos() => [
    {
      'id': 'cat_ing_001',
      'nombre': 'Salario',
      'emoji': '💼',
      'tipo': 'ingreso',
    },
    {
      'id': 'cat_ing_002',
      'nombre': 'Ventas',
      'emoji': '🏢',
      'tipo': 'ingreso',
    },
    {
      'id': 'cat_ing_003',
      'nombre': 'Inversiones',
      'emoji': '📈',
      'tipo': 'ingreso',
    },
  ];
  
  // ============================================
  // TRANSACCIONES DE PRUEBA
  // ============================================
  
  static List<Map<String, dynamic>> transaccionesMesEnero2026() => [
    // Ingreso de salario
    {
      'id': 'trans_001',
      'tipo': 'ingreso',
      'categoriaId': 'cat_ing_001',
      'cuentaId': 'cuenta_001',
      'monto': 3000000,
      'fecha': DateTime(2026, 1, 5),
      'descripcion': 'Salario enero',
    },
    
    // Gastos de alimentación
    {
      'id': 'trans_002',
      'tipo': 'gasto',
      'categoriaId': 'cat_001',
      'cuentaId': 'cuenta_001',
      'monto': 150000,
      'fecha': DateTime(2026, 1, 7),
      'descripcion': 'Supermercado semanal',
    },
    {
      'id': 'trans_003',
      'tipo': 'gasto',
      'categoriaId': 'cat_001',
      'cuentaId': 'cuenta_001',
      'monto': 180000,
      'fecha': DateTime(2026, 1, 14),
      'descripcion': 'Supermercado semanal',
    },
    {
      'id': 'trans_004',
      'tipo': 'gasto',
      'categoriaId': 'cat_001',
      'cuentaId': 'cuenta_001',
      'monto': 160000,
      'fecha': DateTime(2026, 1, 21),
      'descripcion': 'Supermercado semanal',
    },
    {
      'id': 'trans_005',
      'tipo': 'gasto',
      'categoriaId': 'cat_001',
      'cuentaId': 'cuenta_001',
      'monto': 170000,
      'fecha': DateTime(2026, 1, 28),
      'descripcion': 'Supermercado semanal',
    },
    
    // Gastos de vivienda
    {
      'id': 'trans_006',
      'tipo': 'gasto',
      'categoriaId': 'cat_003',
      'cuentaId': 'cuenta_001',
      'monto': 1000000,
      'fecha': DateTime(2026, 1, 1),
      'descripcion': 'Arriendo enero',
    },
    {
      'id': 'trans_007',
      'tipo': 'gasto',
      'categoriaId': 'cat_003',
      'cuentaId': 'cuenta_001',
      'monto': 250000,
      'fecha': DateTime(2026, 1, 10),
      'descripcion': 'Servicios públicos',
    },
    
    // Gastos de transporte
    {
      'id': 'trans_008',
      'tipo': 'gasto',
      'categoriaId': 'cat_002',
      'cuentaId': 'cuenta_002',
      'monto': 50000,
      'fecha': DateTime(2026, 1, 8),
      'descripcion': 'Gasolina',
    },
    {
      'id': 'trans_009',
      'tipo': 'gasto',
      'categoriaId': 'cat_002',
      'cuentaId': 'cuenta_002',
      'monto': 45000,
      'fecha': DateTime(2026, 1, 15),
      'descripcion': 'Gasolina',
    },
    {
      'id': 'trans_010',
      'tipo': 'gasto',
      'categoriaId': 'cat_002',
      'cuentaId': 'cuenta_002',
      'monto': 48000,
      'fecha': DateTime(2026, 1, 22),
      'descripcion': 'Gasolina',
    },
    
    // Entretenimiento
    {
      'id': 'trans_011',
      'tipo': 'gasto',
      'categoriaId': 'cat_004',
      'cuentaId': 'cuenta_003',
      'monto': 80000,
      'fecha': DateTime(2026, 1, 12),
      'descripcion': 'Cine',
    },
    {
      'id': 'trans_012',
      'tipo': 'gasto',
      'categoriaId': 'cat_004',
      'cuentaId': 'cuenta_001',
      'monto': 150000,
      'fecha': DateTime(2026, 1, 18),
      'descripcion': 'Restaurante',
    },
    {
      'id': 'trans_013',
      'tipo': 'gasto',
      'categoriaId': 'cat_004',
      'cuentaId': 'cuenta_003',
      'monto': 60000,
      'fecha': DateTime(2026, 1, 25),
      'descripcion': 'Bar',
    },
  ];
  
  // ============================================
  // PRESUPUESTOS DE PRUEBA
  // ============================================
  
  static List<Map<String, dynamic>> presupuestosEnero2026() => [
    {
      'id': 'pres_001',
      'categoriaId': 'cat_001',
      'montoPlaneado': 600000,
      'montoGastado': 660000, // Excedido
      'periodo': DateTime(2026, 1, 1),
      'alertaActiva': true,
      'umbralAlerta': 80,
    },
    {
      'id': 'pres_002',
      'categoriaId': 'cat_002',
      'montoPlaneado': 200000,
      'montoGastado': 143000,
      'periodo': DateTime(2026, 1, 1),
      'alertaActiva': true,
      'umbralAlerta': 80,
    },
    {
      'id': 'pres_003',
      'categoriaId': 'cat_003',
      'montoPlaneado': 1300000,
      'montoGastado': 1250000,
      'periodo': DateTime(2026, 1, 1),
      'alertaActiva': true,
      'umbralAlerta': 90,
    },
    {
      'id': 'pres_004',
      'categoriaId': 'cat_004',
      'montoPlaneado': 300000,
      'montoGastado': 290000, // Cerca del límite
      'periodo': DateTime(2026, 1, 1),
      'alertaActiva': true,
      'umbralAlerta': 80,
    },
  ];
  
  // ============================================
  // METAS DE PRUEBA
  // ============================================
  
  static List<Map<String, dynamic>> metasActivas() => [
    {
      'id': 'meta_001',
      'nombre': 'Vacaciones Cartagena',
      'emoji': '🏖️',
      'montoObjetivo': 4000000,
      'montoActual': 2500000, // 62.5%
      'fechaObjetivo': DateTime(2026, 7, 15),
      'descripcion': 'Vacaciones de mitad de año',
    },
    {
      'id': 'meta_002',
      'nombre': 'Fondo de Emergencia',
      'emoji': '🆘',
      'montoObjetivo': 9000000, // 3 meses de gastos
      'montoActual': 4500000, // 50%
      'fechaObjetivo': DateTime(2026, 12, 31),
      'descripcion': '3 meses de gastos',
    },
    {
      'id': 'meta_003',
      'nombre': 'Carro Nuevo',
      'emoji': '🚗',
      'montoObjetivo': 30000000,
      'montoActual': 8000000, // 26.7%
      'fechaObjetivo': DateTime(2027, 6, 30),
      'descripcion': 'Cuota inicial para carro',
    },
  ];
  
  // ============================================
  // ESCENARIOS COMPLETOS
  // ============================================
  
  /// Escenario: Usuario nuevo sin actividad
  static Map<String, dynamic> escenarioUsuarioNuevo() => {
    'usuario': usuarioBasico(),
    'cuentas': [],
    'transacciones': [],
    'presupuestos': [],
    'metas': [],
  };
  
  /// Escenario: Usuario con configuración básica
  static Map<String, dynamic> escenarioConfiguracionBasica() => {
    'usuario': usuarioBasico(),
    'cuentas': cuentasBasicas(),
    'categorias': [...categoriasGastos(), ...categoriasIngresos()],
    'transacciones': [],
    'presupuestos': [],
    'metas': [],
  };
  
  /// Escenario: Mes completo de actividad
  static Map<String, dynamic> escenarioMesCompleto() => {
    'usuario': usuarioBasico(),
    'cuentas': cuentasBasicas(),
    'categorias': [...categoriasGastos(), ...categoriasIngresos()],
    'transacciones': transaccionesMesEnero2026(),
    'presupuestos': presupuestosEnero2026(),
    'metas': metasActivas(),
  };
  
  /// Escenario: Presupuesto excedido
  static Map<String, dynamic> escenarioPresupuestoExcedido() => {
    'usuario': usuarioBasico(),
    'cuentas': [cuentasBasicas()[0]],
    'categorias': [categoriasGastos()[0]], // Alimentación
    'presupuesto': {
      'id': 'pres_test',
      'categoriaId': 'cat_001',
      'montoPlaneado': 500000,
      'montoGastado': 550000, // Excedido
    },
    'transacciones': [
      {
        'tipo': 'gasto',
        'categoriaId': 'cat_001',
        'monto': 200000,
        'fecha': DateTime.now().subtract(Duration(days: 5)),
      },
      {
        'tipo': 'gasto',
        'categoriaId': 'cat_001',
        'monto': 180000,
        'fecha': DateTime.now().subtract(Duration(days: 3)),
      },
      {
        'tipo': 'gasto',
        'categoriaId': 'cat_001',
        'monto': 170000,
        'fecha': DateTime.now().subtract(Duration(days: 1)),
      },
    ],
  };
  
  /// Escenario: Meta próxima a cumplirse
  static Map<String, dynamic> escenarioMetaCasiCompleta() => {
    'usuario': usuarioBasico(),
    'cuentas': [cuentasBasicas()[0]],
    'meta': {
      'id': 'meta_test',
      'nombre': 'Computador Nuevo',
      'montoObjetivo': 2000000,
      'montoActual': 1900000, // 95%
      'fechaObjetivo': DateTime.now().add(Duration(days: 30)),
    },
  };
  
  /// Escenario: Múltiples transferencias
  static Map<String, dynamic> escenarioTransferencias() => {
    'usuario': usuarioBasico(),
    'cuentas': cuentasBasicas(),
    'transacciones': [
      {
        'tipo': 'transferencia',
        'cuentaOrigenId': 'cuenta_001',
        'cuentaDestinoId': 'cuenta_002',
        'monto': 100000,
        'fecha': DateTime.now(),
        'descripcion': 'Transferencia para efectivo',
      },
      {
        'tipo': 'transferencia',
        'cuentaOrigenId': 'cuenta_001',
        'cuentaDestinoId': 'cuenta_003',
        'monto': 50000,
        'fecha': DateTime.now(),
        'descripcion': 'Transferencia a Nequi',
      },
    ],
  };
  
  /// Escenario: Deuda con pagos pendientes
  static Map<String, dynamic> escenarioConDeudas() => {
    'usuario': usuarioBasico(),
    'cuentas': [cuentasBasicas()[0]],
    'deudas': [
      {
        'id': 'deuda_001',
        'nombre': 'Tarjeta Visa',
        'montoTotal': 1500000,
        'saldoActual': 800000,
        'cuotaMensual': 200000,
        'tasaInteres': 2.5,
        'fechaProximoPago': DateTime.now().add(Duration(days: 5)),
      },
      {
        'id': 'deuda_002',
        'nombre': 'Crédito Carro',
        'montoTotal': 20000000,
        'saldoActual': 15000000,
        'cuotaMensual': 800000,
        'tasaInteres': 1.2,
        'fechaProximoPago': DateTime.now().add(Duration(days: 10)),
      },
    ],
  };
  
  // ============================================
  // CONFIGURACIONES DE USUARIO
  // ============================================
  
  static Map<String, dynamic> configuracionDefault() => {
    'alertasActivas': true,
    'notificacionesPush': true,
    'notificacionesEmail': false,
    'monedaPrincipal': 'COP',
    'objetivoAhorro': 20, // porcentaje
    'umbralSaldoBajo': 100000,
    'tema': 'claro',
    'mostrarEmojis': true,
  };
  
  static Map<String, dynamic> configuracionAhorradorAgresivo() => {
    'alertasActivas': true,
    'notificacionesPush': true,
    'notificacionesEmail': true,
    'monedaPrincipal': 'COP',
    'objetivoAhorro': 40, // porcentaje alto
    'umbralSaldoBajo': 500000, // umbral alto
    'tema': 'claro',
    'mostrarEmojis': true,
  };
  
  static Map<String, dynamic> configuracionMinimalista() => {
    'alertasActivas': false,
    'notificacionesPush': false,
    'notificacionesEmail': false,
    'monedaPrincipal': 'COP',
    'objetivoAhorro': 10,
    'umbralSaldoBajo': 50000,
    'tema': 'oscuro',
    'mostrarEmojis': false,
  };
  
  // ============================================
  // DATOS PARA REPORTES
  // ============================================
  
  static Map<String, dynamic> datosReporteMensual() => {
    'mes': DateTime(2026, 1, 1),
    'ingresos': {
      'total': 3000000,
      'porCategoria': {
        'Salario': 3000000,
      },
    },
    'gastos': {
      'total': 2483000,
      'porCategoria': {
        'Alimentación': 660000,
        'Vivienda': 1250000,
        'Transporte': 143000,
        'Entretenimiento': 290000,
        'Otros': 140000,
      },
    },
    'ahorro': 517000,
    'tasaAhorro': 17.23,
  };
  
  // ============================================
  // DATOS PARA GRÁFICOS
  // ============================================
  
  static List<Map<String, dynamic>> evolucionPatrimonio6Meses() => [
    {'mes': DateTime(2025, 8, 1), 'patrimonio': 5000000},
    {'mes': DateTime(2025, 9, 1), 'patrimonio': 5500000},
    {'mes': DateTime(2025, 10, 1), 'patrimonio': 5800000},
    {'mes': DateTime(2025, 11, 1), 'patrimonio': 6100000},
    {'mes': DateTime(2025, 12, 1), 'patrimonio': 6300000},
    {'mes': DateTime(2026, 1, 1), 'patrimonio': 6800000},
  ];
  
  static List<Map<String, dynamic>> evolucionAhorro12Meses() => [
    {'mes': DateTime(2025, 2, 1), 'ahorro': 400000, 'tasa': 13.3},
    {'mes': DateTime(2025, 3, 1), 'ahorro': 450000, 'tasa': 15.0},
    {'mes': DateTime(2025, 4, 1), 'ahorro': 380000, 'tasa': 12.7},
    {'mes': DateTime(2025, 5, 1), 'ahorro': 520000, 'tasa': 17.3},
    {'mes': DateTime(2025, 6, 1), 'ahorro': 600000, 'tasa': 20.0},
    {'mes': DateTime(2025, 7, 1), 'ahorro': 550000, 'tasa': 18.3},
    {'mes': DateTime(2025, 8, 1), 'ahorro': 480000, 'tasa': 16.0},
    {'mes': DateTime(2025, 9, 1), 'ahorro': 500000, 'tasa': 16.7},
    {'mes': DateTime(2025, 10, 1), 'ahorro': 580000, 'tasa': 19.3},
    {'mes': DateTime(2025, 11, 1), 'ahorro': 620000, 'tasa': 20.7},
    {'mes': DateTime(2025, 12, 1), 'ahorro': 700000, 'tasa': 23.3},
    {'mes': DateTime(2026, 1, 1), 'ahorro': 517000, 'tasa': 17.2},
  ];
}
