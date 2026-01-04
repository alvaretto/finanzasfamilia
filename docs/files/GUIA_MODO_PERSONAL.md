# Guía de Finanzas Personales - Modo Personal

## Documento de Diseño para Usuarios No Empresariales
**Proyecto:** Finanzas Familiares AS  
**Fecha:** 4 de enero de 2026  
**Audiencia:** Personas naturales y familias (sin obligación contable)

---

## Tabla de Contenido

1. [Filosofía del Modo Personal](#filosofía-del-modo-personal)
2. [Principios Financieros Fundamentales](#principios-financieros-fundamentales)
3. [Terminología Amigable](#terminología-amigable)
4. [Estructura de Información Personal](#estructura-de-información-personal)
5. [Categorías y Organización](#categorías-y-organización)
6. [Reportes y Visualizaciones](#reportes-y-visualizaciones)
7. [Indicadores Financieros Personales](#indicadores-financieros-personales)
8. [Guía de Implementación Técnica](#guía-de-implementación-técnica)
9. [Educación Financiera Integrada](#educación-financiera-integrada)
10. [Casos de Uso Prácticos](#casos-de-uso-prácticos)

---

## 1. Filosofía del Modo Personal

### 1.1 Objetivo Principal

**Hacer las finanzas personales simples, comprensibles y útiles para todos.**

**NO es:**

- Un sistema contable formal
- Una herramienta empresarial
- Un requisito legal

**SÍ es:**

- Un organizador financiero personal
- Una herramienta de toma de decisiones
- Un educador financiero
- Un compañero de ahorro y metas

### 1.2 Principios de Diseño

**1. Simplicidad primero:**

- Terminología de todos los días
- Sin jerga técnica
- Conceptos visuales e intuitivos

**2. Educación invisible:**

- Aprender haciendo
- Consejos contextuales
- Explicaciones cuando se necesitan

**3. Utilidad práctica:**

- Respuestas a preguntas reales
- Alertas accionables
- Insights relevantes

**4. Flexibilidad:**

- El usuario controla su nivel de detalle
- Categorías personalizables
- Reportes adaptables

---

## 2. Principios Financieros Fundamentales

### 2.1 Los 6 Principios (Adaptados de Normas Contables)

Aunque no estás obligado a seguir normas contables, estos principios te ayudarán a llevar mejor control de tu dinero:

#### Principio 1: **Registra Cuando Ocurre** (Causación)

**En palabras simples:**
> Anota cada movimiento cuando sucede, no cuando el dinero entra o sale de tu cuenta.

**¿Por qué importa?**

- Sabes exactamente qué compraste y cuándo
- Evitas sorpresas en tu cuenta
- Puedes planificar mejor

**Ejemplos prácticos:**

```
❌ MAL:
"Compré el 5 de enero, pero lo registré el 15 cuando me llegó el estado de cuenta"

✅ BIEN:
"Compré el 5 de enero → Lo registré el 5 de enero"
```

**Casos especiales:**

**Compras con tarjeta de crédito:**
```
Fecha de compra: 10 de enero
Registrar: 10 de enero como "Gasto"
Categoría: "Supermercado"
Nota: "Se paga en tarjeta el 25 de enero"
```

**Pagos mensuales recurrentes:**
```
Netflix se cobra automáticamente cada 5
Registrar: El día 5, aunque no veas el cobro inmediatamente
```

#### Principio 2: **Piensa en Continuidad** (Negocio en Marcha)

**En palabras simples:**
> Planifica pensando que mañana también existirás y tendrás gastos.

**¿Por qué importa?**

- No gastes todo hoy
- Construye un colchón de emergencia
- Planifica para el futuro

**Ejemplos prácticos:**

```
✅ Mentalidad correcta:
"Tengo $1,000,000 en el banco"
→ "Tengo que guardar para emergencias"
→ "Puedo gastar máximo $200,000 en caprichos este mes"

❌ Mentalidad incorrecta:
"Tengo $1,000,000 en el banco"
→ "Puedo gastar todo porque tengo suficiente"
```

**Aplicación práctica:**

- Fondo de emergencia: 6 meses de gastos fijos
- Ahorro mensual obligatorio (mínimo 20%)
- No usar ahorros para gastos del día a día

#### Principio 3: **Información Clara y Simple** (Comprensibilidad)

**En palabras simples:**
> Si no lo entiendes, no sirve.

**¿Por qué importa?**

- Tomas mejores decisiones
- No te abrumas
- Realmente usas la información

**Ejemplos prácticos:**

```
❌ Confuso:
"Estado de Situación Patrimonial al 31/12/2025"
Activos Corrientes: $5,234,567
Pasivos No Corrientes: $1,876,432

✅ Claro:
"Tu Dinero - Diciembre 2025"
Lo que tienes: $5,234,567
Lo que debes: $1,876,432
Tu ahorro neto: $3,358,135
```

**Visualización > Números:**
```
En lugar de:
"Gastaste $450,000 en entretenimiento"

Mejor:
📊 "Gastaste $450,000 en entretenimiento
    Esto es el 15% de tus ingresos
    📈 +20% vs mes pasado
    💡 Consejo: Considera reducir salidas"
```

#### Principio 4: **Solo Info Importante** (Relevancia)

**En palabras simples:**
> Registra lo que te ayuda a tomar decisiones, ignora lo irrelevante.

**¿Por qué importa?**

- No pierdes tiempo
- Te enfocas en lo importante
- La app no se vuelve una carga

**Ejemplos prácticos:**

**QUÉ registrar:**
```
✅ SÍ registrar:

- Compra de supermercado: $150,000
- Pago de arriendo: $1,200,000
- Salida a comer: $80,000
- Pago de tarjeta: $500,000

❌ NO necesitas registrar:

- Cada chicle de $1,000
- Cada propina de $2,000
- Cada parqueadero de $3,000
```

**Umbral recomendado:**
```
Registra si:

- Es > $10,000 COP, O
- Es un gasto recurrente, O
- Es importante para tu presupuesto
```

#### Principio 5: **Información Confiable** (Fiabilidad)

**En palabras simples:**
> Los números deben ser correctos para que confíes en ellos.

**¿Por qué importa?**

- Tomas decisiones basadas en realidad
- Evitas errores costosos
- Tienes paz mental

**Ejemplos prácticos:**

**Validación de saldos:**
```
Cada semana:

1. Compara saldo en la app vs saldo real en banco
2. Si hay diferencia > $50,000:
   → Revisa transacciones
   → Ajusta si es necesario

3. Documenta la razón del ajuste
```

**Categorización correcta:**
```
❌ MAL:
Compra de ropa → "Entretenimiento"
Pago de servicios → "Otros"

✅ BIEN:
Compra de ropa → "Ropa y Calzado"
Pago de servicios → "Servicios Públicos"
```

**Verificación de datos:**
```dart
void validarTransaccion(Transaccion t) {
  // Monto debe ser > 0
  if (t.monto <= 0) throw "Monto inválido";
  
  // Fecha no puede ser futura
  if (t.fecha.isAfter(DateTime.now())) 
    throw "Fecha no puede ser futura";
  
  // Categoría es obligatoria
  if (t.categoria == null) 
    throw "Selecciona una categoría";
}
```

#### Principio 6: **Compara en el Tiempo** (Comparabilidad)

**En palabras simples:**
> Usa el mismo método siempre para poder comparar mes a mes.

**¿Por qué importa?**

- Ves tendencias
- Identificas problemas temprano
- Celebras logros

**Ejemplos prácticos:**

**Comparación mensual:**
```
Enero 2026:
Ingresos: $3,000,000
Gastos: $2,400,000
Ahorro: $600,000 (20%)

Diciembre 2025:
Ingresos: $3,000,000
Gastos: $2,700,000
Ahorro: $300,000 (10%)

📊 Análisis:
✅ Mejoraste tu ahorro en 10%
🎯 Mantén esta tendencia
```

**Consistencia en categorías:**
```
❌ MAL:
Enero: "Comida"
Febrero: "Alimentación"
Marzo: "Supermercado y restaurantes"
→ No puedes comparar

✅ BIEN:
Siempre: "Alimentación"
→ Puedes ver tendencias claras
```

---

## 3. Terminología Amigable

### 3.1 Diccionario de Traducción

**De términos contables a lenguaje cotidiano:**

| Término Contable | Término Amigable | Explicación Simple |
|-----------------|------------------|-------------------|
| Estado de Situación Financiera | Mi Balance Personal | Una foto de tu situación financiera hoy |
| Activos | Lo que Tengo | Todo tu dinero y cosas de valor |
| Pasivos | Lo que Debo | Todas tus deudas |
| Patrimonio | Mis Ahorros Netos | Lo que realmente es tuyo (Lo que tienes - Lo que debes) |
| Estado de Resultados | Mis Ingresos y Gastos | Resumen de tu dinero del mes |
| Ingresos | Dinero que Recibo | Salario, ventas, regalos, etc. |
| Gastos | Dinero que Pago | Todo lo que compras o pagas |
| Flujo de Efectivo | Movimiento de Dinero | Cómo entra y sale el dinero |
| Presupuesto | Plan de Gastos | Cuánto planeas gastar en cada cosa |
| Causación | Cuando Sucede | Registrar cuando compras, no cuando pagas |
| Partida Doble | Movimiento Completo | Si mueves dinero, sale de un lado y entra a otro |
| Costo Histórico | Precio de Compra | Lo que pagaste originalmente |
| Depreciación | Pérdida de Valor | Cuánto se desvalúa algo con el tiempo |
| Cuenta por Cobrar | Dinero que me Deben | Plata que te van a pagar |
| Cuenta por Pagar | Dinero que Debo | Plata que tienes que pagar |

### 3.2 Interfaz de Usuario - Textos Amigables

**Secciones principales:**

```dart
// ❌ Nombres técnicos
"Estados Financieros"
"Balance General"
"Estado de Resultados"
"Cuentas del Activo"

// ✅ Nombres amigables
"Mi Dinero"
"Resumen del Mes"
"¿Cómo voy?"
"Mis Cuentas"
```

**Botones y acciones:**

```dart
// ❌ Técnico
"Registrar Transacción"
"Crear Asiento Contable"
"Categorizar Movimiento"

// ✅ Amigable
"Anotar un Gasto"
"Registrar Ingreso"
"¿En qué gastaste?"
```

**Mensajes y notificaciones:**

```dart
// ❌ Formal
"Se ha excedido el límite presupuestario asignado"
"Saldo insuficiente en cuenta de activos líquidos"

// ✅ Conversacional
"¡Ojo! Ya gastaste más de lo planeado en entretenimiento"
"Te estás quedando sin efectivo. ¿Necesitas transferir?"
```

---

## 4. Estructura de Información Personal

### 4.1 "Lo que Tengo" (Activos)

**Organización simple y visual:**

```
💰 MIS CUENTAS
│
├── 💵 Efectivo
│   └── Billetera: $150,000
│
├── 🏦 Bancos
│   ├── Bancolombia Ahorros: $2,500,000
│   ├── Davivienda Corriente: $800,000
│   └── Nequi: $200,000
│
├── 💳 Tarjetas de Débito
│   └── (incluidas en bancos)
│
├── 📈 Inversiones
│   ├── CDT Banco: $5,000,000
│   ├── Acciones (opcional): $1,000,000
│   └── Criptomonedas (opcional): $500,000
│
└── 🤝 Me Deben
    └── Préstamo a amigo: $300,000

TOTAL LO QUE TENGO: $10,450,000
```

**Implementación técnica:**

```dart
class CuentaPersonal {
  final String id;
  final TipoCuenta tipo;
  final String nombre;
  final String emoji; // Para UI amigable
  final double saldo;
  final String moneda;
  final bool incluirEnTotal; // Algunas no cuentan (ej: bienes)
  
  // Categorías amigables
  String get categoriaAmigable {
    switch (tipo) {
      case TipoCuenta.efectivo:
        return "💵 Efectivo";
      case TipoCuenta.banco:
        return "🏦 Banco";
      case TipoCuenta.inversion:
        return "📈 Inversiones";
      case TipoCuenta.porCobrar:
        return "🤝 Me Deben";
      default:
        return "💰 Otros";
    }
  }
}

enum TipoCuenta {
  efectivo,
  banco,
  inversion,
  porCobrar,
}
```

### 4.2 "Lo que Debo" (Pasivos)

**Organización clara por urgencia:**

```
💳 MIS DEUDAS
│
├── 🔴 Urgente (Este mes)
│   ├── Tarjeta Visa: $450,000
│   ├── Servicios públicos: $180,000
│   └── Arriendo: $1,200,000
│
├── 🟡 Mediano Plazo (Este año)
│   ├── Crédito carro: $800,000/mes (12 cuotas)
│   └── Préstamo familiar: $200,000/mes (6 cuotas)
│
└── 🟢 Largo Plazo (Años)
    └── Crédito hipotecario: $1,500,000/mes (180 cuotas)

TOTAL LO QUE DEBO: $4,330,000
```

**Implementación técnica:**

```dart
class DeudaPersonal {
  final String id;
  final String nombre;
  final double montoTotal;
  final double saldoActual;
  final double cuotaMensual;
  final int cuotasRestantes;
  final DateTime fechaProximoPago;
  final double tasaInteres;
  final Urgencia urgencia;
  
  // Calcula urgencia automáticamente
  Urgencia get urgenciaCalculada {
    final dias = fechaProximoPago.difference(DateTime.now()).inDays;
    if (dias <= 7) return Urgencia.urgente;
    if (dias <= 30) return Urgencia.media;
    return Urgencia.baja;
  }
  
  // Mensaje amigable
  String get mensajeAmigable {
    if (urgenciaCalculada == Urgencia.urgente) {
      return "⚠️ Pagar en ${fechaProximoPago.difference(DateTime.now()).inDays} días";
    }
    return "📅 Próximo pago: ${DateFormat('d MMM').format(fechaProximoPago)}";
  }
}

enum Urgencia { urgente, media, baja }
```

### 4.3 "Mis Ahorros Netos" (Patrimonio)

**El número más importante:**

```
🎯 TU PATRIMONIO

Lo que tienes:      $10,450,000
Lo que debes:       - $4,330,000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tu ahorro neto:     $6,120,000

📊 Comparación:
Mes pasado:         $5,800,000
Cambio:             +$320,000 (+5.5%) ✅

🎉 ¡Vas bien! Tu patrimonio está creciendo.
```

**Implementación técnica:**

```dart
class PatrimonioPersonal {
  final double totalActivos;
  final double totalPasivos;
  
  double get patrimonioNeto => totalActivos - totalPasivos;
  
  // Comparación con mes anterior
  double calcularCambio(PatrimonioPersonal mesAnterior) {
    return patrimonioNeto - mesAnterior.patrimonioNeto;
  }
  
  double calcularPorcentajeCambio(PatrimonioPersonal mesAnterior) {
    if (mesAnterior.patrimonioNeto == 0) return 0;
    return ((patrimonioNeto - mesAnterior.patrimonioNeto) / 
            mesAnterior.patrimonioNeto) * 100;
  }
  
  // Mensaje motivacional
  String get mensajeMotivacional {
    final cambio = calcularPorcentajeCambio(mesAnterior);
    
    if (cambio > 5) {
      return "🎉 ¡Excelente! Tu patrimonio creció ${cambio.toStringAsFixed(1)}%";
    } else if (cambio > 0) {
      return "👍 Bien! Tu patrimonio aumentó ${cambio.toStringAsFixed(1)}%";
    } else if (cambio == 0) {
      return "➡️ Tu patrimonio se mantuvo estable";
    } else {
      return "⚠️ Tu patrimonio disminuyó ${(-cambio).toStringAsFixed(1)}%. Revisa tus gastos.";
    }
  }
}
```

---

## 5. Categorías y Organización

### 5.1 Categorías de Ingresos (Dinero que Recibes)

**Estructura sugerida:**

```
💰 MIS INGRESOS
│
├── 💼 Trabajo
│   ├── Salario principal
│   ├── Horas extras
│   ├── Bonos
│   └── Comisiones
│
├── 🏢 Negocios
│   ├── Ventas
│   ├── Servicios
│   └── Comisiones
│
├── 🏠 Propiedades
│   ├── Arriendo de apartamento
│   └── Arriendo de local
│
├── 📈 Inversiones
│   ├── Intereses bancarios
│   ├── Dividendos
│   └── Ganancias acciones
│
└── 🎁 Otros
    ├── Regalos
    ├── Reembolsos
    └── Devoluciones
```

**Implementación:**

```dart
class CategoriaIngreso {
  final String id;
  final String nombre;
  final String emoji;
  final String? grupo; // Para jerarquía
  final Color color;
  
  static List<CategoriaIngreso> categoriasDefault = [
    CategoriaIngreso(
      nombre: "Salario",
      emoji: "💼",
      grupo: "Trabajo",
      color: Colors.green,
    ),
    CategoriaIngreso(
      nombre: "Ventas",
      emoji: "🏢",
      grupo: "Negocios",
      color: Colors.blue,
    ),
    // ... más categorías
  ];
}
```

### 5.2 Categorías de Gastos (Dinero que Pagas)

**Organización por tipo de gasto:**

**A. GASTOS FIJOS (Siempre los mismos)**

```
🏠 VIVIENDA
├── Arriendo / Cuota
├── Administración
├── Servicios Públicos
│   ├── Luz
│   ├── Agua
│   ├── Gas
│   ├── Internet
│   └── Celular
└── Impuestos (predial, etc.)

🚗 TRANSPORTE
├── Gasolina / Transporte público
├── Cuota del carro
├── Seguro
└── Mantenimiento

💳 DEUDAS
├── Tarjetas de crédito
├── Préstamos
└── Créditos

👨‍👩‍👧‍👦 FAMILIA
├── Educación (colegio, universidad)
├── Salud (medicina prepagada, seguros)
└── Cuidado (jardín, niñera)
```

**B. GASTOS VARIABLES (Cambian cada mes)**

```
🛒 MERCADO Y ALIMENTACIÓN
├── Supermercado
├── Tienda
└── Restaurantes

👗 PERSONAL
├── Ropa y calzado
├── Peluquería
└── Cuidado personal

🎮 ENTRETENIMIENTO
├── Salidas (cine, teatro)
├── Deportes
├── Hobbies
└── Suscripciones (Netflix, Spotify, etc.)

🎁 REGALOS Y OCASIONES
├── Cumpleaños
├── Navidad
└── Otras fechas

⚕️ SALUD
├── Medicamentos
├── Consultas médicas
└── Odontología

🎓 EDUCACIÓN
├── Cursos
├── Libros
└── Materiales

💰 OTROS
└── Gastos varios
```

**Implementación completa:**

```dart
class CategoriaGasto {
  final String id;
  final String nombre;
  final String emoji;
  final TipoGasto tipo; // fijo o variable
  final String? grupo;
  final Color color;
  final double? presupuestoSugerido; // % de ingresos
  
  static List<CategoriaGasto> categoriasDefault = [
    // FIJOS
    CategoriaGasto(
      nombre: "Arriendo",
      emoji: "🏠",
      tipo: TipoGasto.fijo,
      grupo: "Vivienda",
      color: Colors.brown,
      presupuestoSugerido: 30, // 30% de ingresos máximo
    ),
    CategoriaGasto(
      nombre: "Servicios Públicos",
      emoji: "💡",
      tipo: TipoGasto.fijo,
      grupo: "Vivienda",
      color: Colors.orange,
      presupuestoSugerido: 10,
    ),
    
    // VARIABLES
    CategoriaGasto(
      nombre: "Supermercado",
      emoji: "🛒",
      tipo: TipoGasto.variable,
      grupo: "Alimentación",
      color: Colors.green,
      presupuestoSugerido: 20,
    ),
    CategoriaGasto(
      nombre: "Entretenimiento",
      emoji: "🎮",
      tipo: TipoGasto.variable,
      grupo: "Ocio",
      color: Colors.purple,
      presupuestoSugerido: 10,
    ),
    // ... más categorías
  ];
}

enum TipoGasto { fijo, variable }
```

### 5.3 Regla 50/30/20 Integrada

**División recomendada de ingresos:**

```
📊 REGLA 50/30/20

Tus ingresos: $3,000,000

🏠 50% - Necesidades ($1,500,000)
   Vivienda, alimentación, transporte,
   servicios, deudas mínimas
   
🎮 30% - Gustos ($900,000)
   Entretenimiento, salidas, hobbies,
   compras no esenciales
   
💰 20% - Ahorros ($600,000)
   Inversiones, fondo de emergencia,
   pago extra de deudas
```

**Implementación:**

```dart
class RecomendacionPresupuesto {
  final double ingresosMensuales;
  
  // Regla 50/30/20
  double get necesidades => ingresosMensuales * 0.50;
  double get gustos => ingresosMensuales * 0.30;
  double get ahorros => ingresosMensuales * 0.20;
  
  // Validar presupuesto actual
  Map<String, dynamic> validarPresupuesto(
    double gastosNecesidades,
    double gastosGustos,
    double ahorroActual,
  ) {
    return {
      'necesidades': {
        'presupuesto': necesidades,
        'actual': gastosNecesidades,
        'diferencia': necesidades - gastosNecesidades,
        'porcentaje': (gastosNecesidades / ingresosMensuales) * 100,
        'estado': gastosNecesidades <= necesidades ? 'bien' : 'alto',
      },
      'gustos': {
        'presupuesto': gustos,
        'actual': gastosGustos,
        'diferencia': gustos - gastosGustos,
        'porcentaje': (gastosGustos / ingresosMensuales) * 100,
        'estado': gastosGustos <= gustos ? 'bien' : 'alto',
      },
      'ahorros': {
        'objetivo': ahorros,
        'actual': ahorroActual,
        'diferencia': ahorroActual - ahorros,
        'porcentaje': (ahorroActual / ingresosMensuales) * 100,
        'estado': ahorroActual >= ahorros ? 'bien' : 'bajo',
      },
    };
  }
}
```

---

## 6. Reportes y Visualizaciones

### 6.1 "Mi Resumen del Mes"

**Diseño amigable y visual:**

```
📅 ENERO 2026

💰 DINERO QUE RECIBÍ
Salario:               $3,000,000
Venta freelance:         $500,000
                      ────────────
Total:                $3,500,000

💸 DINERO QUE GASTÉ
🏠 Vivienda:           $1,200,000 (34%)
🛒 Alimentación:         $700,000 (20%)
🚗 Transporte:           $300,000 (9%)
🎮 Entretenimiento:      $250,000 (7%)
💳 Deudas:               $400,000 (11%)
👗 Personal:             $150,000 (4%)
⚕️ Salud:                $100,000 (3%)
💰 Otros:                $200,000 (6%)
                      ────────────
Total:                $3,300,000

💎 LO QUE AHORRÉ
$200,000 (5.7% de tus ingresos)

📊 ANÁLISIS
✅ Gastaste menos de lo que ganaste
⚠️ Tu ahorro está por debajo del 20% recomendado
💡 Intenta reducir entretenimiento y otros

🎯 PRÓXIMO MES
Objetivo de ahorro: $700,000 (20%)
Necesitas reducir gastos en: $500,000
```

**Implementación:**

```dart
class ResumenMensual {
  final DateTime mes;
  final List<Transaccion> ingresos;
  final List<Transaccion> gastos;
  
  double get totalIngresos => 
    ingresos.fold(0, (sum, t) => sum + t.monto);
    
  double get totalGastos => 
    gastos.fold(0, (sum, t) => sum + t.monto);
    
  double get ahorro => totalIngresos - totalGastos;
  double get tasaAhorro => (ahorro / totalIngresos) * 100;
  
  // Gastos por categoría
  Map<String, double> get gastosPorCategoria {
    final Map<String, double> resultado = {};
    for (var gasto in gastos) {
      final categoria = gasto.categoria;
      resultado[categoria] = (resultado[categoria] ?? 0) + gasto.monto;
    }
    return resultado;
  }
  
  // Porcentaje por categoría
  Map<String, double> get porcentajePorCategoria {
    final gastosCat = gastosPorCategoria;
    return gastosCat.map((cat, monto) => 
      MapEntry(cat, (monto / totalGastos) * 100)
    );
  }
  
  // Mensaje de análisis
  String get mensajeAnalisis {
    final mensajes = <String>[];
    
    if (ahorro > 0) {
      mensajes.add("✅ Gastaste menos de lo que ganaste");
    } else {
      mensajes.add("⚠️ Gastaste más de lo que ganaste");
    }
    
    if (tasaAhorro >= 20) {
      mensajes.add("🎉 ¡Excelente! Ahorraste el ${tasaAhorro.toStringAsFixed(1)}%");
    } else if (tasaAhorro >= 10) {
      mensajes.add("👍 Buen ahorro del ${tasaAhorro.toStringAsFixed(1)}%");
    } else if (tasaAhorro > 0) {
      mensajes.add("⚠️ Tu ahorro del ${tasaAhorro.toStringAsFixed(1)}% está bajo. Objetivo: 20%");
    } else {
      mensajes.add("🔴 No ahorraste este mes. Revisa tus gastos.");
    }
    
    // Categoría con mayor gasto
    final mayorGasto = gastosPorCategoria.entries
      .reduce((a, b) => a.value > b.value ? a : b);
    mensajes.add("📊 Mayor gasto: ${mayorGasto.key} (${((mayorGasto.value/totalGastos)*100).toStringAsFixed(1)}%)");
    
    return mensajes.join('\n');
  }
}
```

### 6.2 "¿Cómo Voy?" (Dashboard Principal)

**Vista rápida y accionable:**

```
🏠 PANTALLA PRINCIPAL

👋 Hola, Juan!
Hoy es lunes, 6 de enero de 2026

💰 TUS CUENTAS
┌─────────────────────────────┐
│ 🏦 Total disponible         │
│    $3,650,000               │
│                             │
│ Bancolombia:  $2,500,000    │
│ Davivienda:     $800,000    │
│ Efectivo:       $200,000    │
│ Nequi:          $150,000    │
└─────────────────────────────┘

📊 ESTE MES (Enero)
┌─────────────────────────────┐
│ Llevamos 6 días             │
│                             │
│ Ingresos:    $3,000,000 ✅  │
│ Gastos:        $450,000     │
│ Disponible:  $2,550,000     │
└─────────────────────────────┘

🎯 TU PRESUPUESTO
┌─────────────────────────────┐
│ Vivienda        85% ████░░  │
│ Alimentación    12% █░░░░░  │
│ Transporte      0%  ░░░░░░  │
│ Entretenimiento 18% █░░░░░  │
└─────────────────────────────┘
⚠️ Te pasaste en entretenimiento

💳 PRÓXIMOS PAGOS
┌─────────────────────────────┐
│ 🔴 HOY - Seguro $120,000    │
│ 🟡 En 3 días - Luz $85,000  │
│ 🟢 En 8 días - Gym $90,000  │
└─────────────────────────────┘

🎁 METAS DE AHORRO
┌─────────────────────────────┐
│ 🏖️ Vacaciones              │
│    $2,800,000 / $5,000,000  │
│    ████████░░░░ 56%         │
│    Faltan $2,200,000        │
└─────────────────────────────┘

💡 CONSEJO DEL DÍA
"Llevas gastados $45,000 en café
este mes. Si lo preparas en casa,
ahorrarías ~$30,000/mes"
```

### 6.3 Gráficos y Visualizaciones

**A. Evolución del Ahorro (Línea de tiempo)**

```dart
class GraficoEvolucion extends StatelessWidget {
  final List<ResumenMensual> meses;
  
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: meses.map((m) => FlSpot(
              m.mes.month.toDouble(),
              m.ahorro,
            )).toList(),
            isCurved: true,
            colors: [Colors.green],
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              const meses = ['E', 'F', 'M', 'A', 'M', 'J', 
                            'J', 'A', 'S', 'O', 'N', 'D'];
              return meses[value.toInt() - 1];
            },
          ),
        ),
      ),
    );
  }
}
```

**B. Distribución de Gastos (Gráfico de torta)**

```dart
class GraficoPorcentajes extends StatelessWidget {
  final Map<String, double> gastosPorCategoria;
  final double totalGastos;
  
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: gastosPorCategoria.entries.map((entry) {
          final porcentaje = (entry.value / totalGastos) * 100;
          return PieChartSectionData(
            value: entry.value,
            title: '${porcentaje.toStringAsFixed(0)}%',
            color: _getColorForCategory(entry.key),
            radius: 100,
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

**C. Comparación Mensual (Barras)**

```dart
class GraficoComparacion extends StatelessWidget {
  final List<ResumenMensual> meses;
  
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: meses.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                y: entry.value.totalIngresos,
                colors: [Colors.green],
                width: 15,
              ),
              BarChartRodData(
                y: entry.value.totalGastos,
                colors: [Colors.red],
                width: 15,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
```

---

## 7. Indicadores Financieros Personales

### 7.1 Indicadores Básicos (Automáticos)

**A. Salud Financiera General**

```dart
class SaludFinanciera {
  final double ingresos;
  final double gastos;
  final double totalActivos;
  final double totalPasivos;
  final double gastosFijos;
  final double fondoEmergencia;
  
  // 1. Capacidad de Ahorro
  double get tasaAhorro {
    final ahorro = ingresos - gastos;
    return (ahorro / ingresos) * 100;
  }
  
  String get mensajeTasaAhorro {
    if (tasaAhorro >= 20) return "🎉 Excelente ahorro";
    if (tasaAhorro >= 10) return "👍 Buen ahorro";
    if (tasaAhorro > 0) return "⚠️ Ahorro bajo";
    return "🔴 Sin ahorro";
  }
  
  // 2. Nivel de Endeudamiento
  double get nivelEndeudamiento {
    return (totalPasivos / totalActivos) * 100;
  }
  
  String get mensajeEndeudamiento {
    if (nivelEndeudamiento < 30) return "✅ Deuda saludable";
    if (nivelEndeudamiento < 50) return "⚠️ Deuda moderada";
    return "🔴 Nivel de deuda alto";
  }
  
  // 3. Liquidez (meses de cobertura)
  int get mesesCobertura {
    if (gastosFijos == 0) return 0;
    return (fondoEmergencia / gastosFijos).floor();
  }
  
  String get mensajeLiquidez {
    if (mesesCobertura >= 6) return "✅ Fondo de emergencia sólido";
    if (mesesCobertura >= 3) return "👍 Fondo aceptable";
    if (mesesCobertura >= 1) return "⚠️ Fondo insuficiente";
    return "🔴 Sin fondo de emergencia";
  }
  
  // 4. Puntuación Global (0-100)
  int get puntuacionGlobal {
    int puntos = 0;
    
    // Ahorro (40 puntos máximo)
    if (tasaAhorro >= 20) puntos += 40;
    else if (tasaAhorro >= 15) puntos += 30;
    else if (tasaAhorro >= 10) puntos += 20;
    else if (tasaAhorro >= 5) puntos += 10;
    
    // Endeudamiento (30 puntos máximo)
    if (nivelEndeudamiento < 30) puntos += 30;
    else if (nivelEndeudamiento < 50) puntos += 20;
    else if (nivelEndeudamiento < 70) puntos += 10;
    
    // Liquidez (30 puntos máximo)
    if (mesesCobertura >= 6) puntos += 30;
    else if (mesesCobertura >= 3) puntos += 20;
    else if (mesesCobertura >= 1) puntos += 10;
    
    return puntos;
  }
  
  String get nivelSalud {
    if (puntuacionGlobal >= 80) return "🎉 Excelente";
    if (puntuacionGlobal >= 60) return "👍 Buena";
    if (puntuacionGlobal >= 40) return "⚠️ Regular";
    return "🔴 Necesita atención";
  }
}
```

**Visualización en la app:**

```
🏥 TU SALUD FINANCIERA

Puntuación: 75/100 - 👍 Buena

📊 DETALLES:

💰 Capacidad de Ahorro: 15%
   👍 Buen ahorro
   Objetivo: 20%
   
💳 Nivel de Deuda: 35%
   ⚠️ Deuda moderada
   Ideal: <30%
   
🏦 Fondo de Emergencia: 4 meses
   ✅ Fondo aceptable
   Ideal: 6 meses
   
💡 RECOMENDACIONES:

1. Aumenta tu ahorro en 5% más
2. Reduce tus deudas gradualmente
3. Completa tu fondo de emergencia
```

### 7.2 Indicadores Avanzados (Opcionales)

**B. Análisis de Gastos Hormiga**

```dart
class AnalizadorGastosHormiga {
  final List<Transaccion> transacciones;
  
  // Detectar gastos pequeños frecuentes
  Map<String, dynamic> analizarGastosHormiga() {
    // Filtrar gastos pequeños (< $20,000)
    final gastosHormiga = transacciones
      .where((t) => t.tipo == TipoTransaccion.gasto && t.monto < 20000)
      .toList();
    
    // Agrupar por categoría
    final Map<String, List<Transaccion>> porCategoria = {};
    for (var gasto in gastosHormiga) {
      porCategoria.putIfAbsent(gasto.categoria, () => []).add(gasto);
    }
    
    // Calcular totales
    final analisis = porCategoria.map((cat, gastos) {
      final total = gastos.fold(0.0, (sum, g) => sum + g.monto);
      final frecuencia = gastos.length;
      final promedio = total / frecuencia;
      
      return MapEntry(cat, {
        'total': total,
        'frecuencia': frecuencia,
        'promedio': promedio,
        'impacto': total > 100000 ? 'alto' : total > 50000 ? 'medio' : 'bajo',
      });
    });
    
    return analisis;
  }
  
  String get mensajeGastosHormiga {
    final analisis = analizarGastosHormiga();
    final totalHormiga = analisis.values
      .fold(0.0, (sum, cat) => sum + cat['total']);
    
    if (totalHormiga > 200000) {
      return """
      🐜 GASTOS HORMIGA DETECTADOS
      
      Pequeñas compras que suman: \$${totalHormiga.toStringAsFixed(0)}
      
      Las más frecuentes:
      ${analisis.entries.take(3).map((e) => 
        "• ${e.key}: \$${e.value['total'].toStringAsFixed(0)} (${e.value['frecuencia']} veces)"
      ).join('\n')}
      
      💡 Si reduces estos gastos, podrías ahorrar 
      \$${(totalHormiga * 0.5).toStringAsFixed(0)} al mes
      """;
    }
    
    return "✅ No tienes gastos hormiga significativos";
  }
}
```

**C. Predictor de Gastos**

```dart
class PredictorGastos {
  final List<ResumenMensual> historial; // últimos 6 meses
  
  // Predecir gasto del próximo mes por categoría
  Map<String, double> predecirProximoMes() {
    final predicciones = <String, double>{};
    
    // Obtener todas las categorías
    final categorias = historial
      .expand((m) => m.gastosPorCategoria.keys)
      .toSet();
    
    for (var categoria in categorias) {
      // Calcular promedio de últimos 3 meses
      final ultimos3 = historial.take(3);
      final gastos = ultimos3
        .map((m) => m.gastosPorCategoria[categoria] ?? 0)
        .toList();
      
      final promedio = gastos.reduce((a, b) => a + b) / gastos.length;
      
      // Ajustar por tendencia (simple)
      final primerMes = gastos.first;
      final ultimoMes = gastos.last;
      final tendencia = ultimoMes - primerMes;
      
      predicciones[categoria] = promedio + (tendencia * 0.3);
    }
    
    return predicciones;
  }
  
  String get mensajePrediccion {
    final pred = predecirProximoMes();
    final totalPred = pred.values.reduce((a, b) => a + b);
    final promedioActual = historial.take(3)
      .map((m) => m.totalGastos)
      .reduce((a, b) => a + b) / 3;
    
    final diferencia = totalPred - promedioActual;
    final porcentaje = (diferencia / promedioActual) * 100;
    
    if (porcentaje.abs() > 10) {
      return """
      📊 PREDICCIÓN PRÓXIMO MES
      
      Gastos estimados: \$${totalPred.toStringAsFixed(0)}
      
      ${porcentaje > 0 
        ? "⚠️ Podría aumentar ${porcentaje.toStringAsFixed(1)}%"
        : "✅ Podría disminuir ${(-porcentaje).toStringAsFixed(1)}%"
      }
      
      Categorías con mayor cambio:
      ${_categoriasMayorCambio(pred)}
      """;
    }
    
    return "📊 Tus gastos se mantendrán estables";
  }
}
```

---

## 8. Guía de Implementación Técnica

### 8.1 Modelo de Datos Completo

```dart
// ============================================
// MODELOS PRINCIPALES
// ============================================

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final ConfiguracionPersonal configuracion;
  final DateTime createdAt;
}

class ConfiguracionPersonal {
  final bool mostrarTutoriales;
  final bool notificacionesActivas;
  final double objetivoAhorro; // Porcentaje (ej: 20)
  final String monedaPrincipal; // 'COP'
  final Map<String, bool> categoriasActivas;
  
  // Personalización visual
  final String tema; // 'claro', 'oscuro', 'auto'
  final bool mostrarEmojis;
  final TipoVista vistaPreferida; // 'simple', 'detallada'
}

class Cuenta {
  final String id;
  final String usuarioId;
  final TipoCuenta tipo;
  final String nombre;
  final String emoji;
  final double saldo;
  final String moneda;
  final bool incluirEnTotal;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Métodos útiles
  String get nombreCompleto => "$emoji $nombre";
  
  bool get esEfectivo => tipo == TipoCuenta.efectivo;
  bool get esBanco => tipo == TipoCuenta.banco;
  bool get esInversion => tipo == TipoCuenta.inversion;
}

class Transaccion {
  final String id;
  final String usuarioId;
  final String cuentaId;
  final TipoTransaccion tipo;
  final String categoriaId;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final List<String>? etiquetas;
  final String? nota;
  final DateTime createdAt;
  
  // Para transferencias
  final String? cuentaDestinoId;
  final bool? esRecurrente;
  final String? recurrenciaId;
  
  // Validación
  bool get esValida {
    return monto > 0 && 
           !fecha.isAfter(DateTime.now()) &&
           categoriaId.isNotEmpty;
  }
}

class Categoria {
  final String id;
  final String nombre;
  final String emoji;
  final TipoCategoria tipo; // ingreso, gasto
  final TipoGasto? tipoGasto; // fijo, variable (solo para gastos)
  final String? grupoId; // Para jerarquía
  final Color color;
  final int orden;
  final bool esActiva;
  final bool esPersonalizada; // vs default del sistema
  
  String get nombreCompleto => "$emoji $nombre";
}

class Presupuesto {
  final String id;
  final String usuarioId;
  final String categoriaId;
  final double montoPlaneado;
  final double montoGastado;
  final DateTime inicioP eriodo;
  final DateTime finPeriodo;
  final bool alertaActiva;
  final double? umbralAlerta; // % (ej: 80)
  
  double get disponible => montoPlaneado - montoGastado;
  double get porcentajeUsado => (montoGastado / montoPlaneado) * 100;
  
  bool get excedido => montoGastado > montoPlaneado;
  bool get cercaLimite => umbralAlerta != null && 
                         porcentajeUsado >= umbralAlerta!;
  
  String get mensaje {
    if (excedido) {
      return "⚠️ Te pasaste por \$${(montoGastado - montoPlaneado).toStringAsFixed(0)}";
    } else if (cercaLimite) {
      return "⚠️ Vas en ${porcentajeUsado.toStringAsFixed(0)}% del presupuesto";
    }
    return "✅ Disponible: \$${disponible.toStringAsFixed(0)}";
  }
}

class Meta {
  final String id;
  final String usuarioId;
  final String nombre;
  final String emoji;
  final double montoObjetivo;
  final double montoActual;
  final DateTime fechaObjetivo;
  final String? descripcion;
  final Color color;
  final DateTime createdAt;
  
  double get progreso => (montoActual / montoObjetivo) * 100;
  double get faltante => montoObjetivo - montoActual;
  
  int get diasRestantes {
    return fechaObjetivo.difference(DateTime.now()).inDays;
  }
  
  double get ahorroMensualNecesario {
    final mesesRestantes = diasRestantes / 30;
    if (mesesRestantes <= 0) return 0;
    return faltante / mesesRestantes;
  }
  
  String get mensaje {
    if (montoActual >= montoObjetivo) {
      return "🎉 ¡Meta alcanzada!";
    }
    return "Faltan \$${faltante.toStringAsFixed(0)} - ${progreso.toStringAsFixed(0)}% completado";
  }
}

// ============================================
// ENUMS
// ============================================

enum TipoCuenta { efectivo, banco, inversion, porCobrar }
enum TipoTransaccion { ingreso, gasto, transferencia }
enum TipoCategoria { ingreso, gasto }
enum TipoGasto { fijo, variable }
enum TipoVista { simple, detallada }
```

### 8.2 Servicios y Lógica de Negocio

```dart
// ============================================
// SERVICIO DE TRANSACCIONES
// ============================================

class TransaccionService {
  final Database db;
  final NotificationService notificationService;
  
  // Crear transacción con validaciones
  Future<void> crearTransaccion(Transaccion transaccion) async {
    // Validar
    if (!transaccion.esValida) {
      throw Exception("Transacción inválida");
    }
    
    // Verificar saldo (si es gasto o transferencia)
    if (transaccion.tipo != TipoTransaccion.ingreso) {
      final cuenta = await db.getCuenta(transaccion.cuentaId);
      if (cuenta.saldo < transaccion.monto) {
        throw Exception("Saldo insuficiente");
      }
    }
    
    // Guardar transacción
    await db.insertTransaccion(transaccion);
    
    // Actualizar saldo de cuenta(s)
    await _actualizarSaldos(transaccion);
    
    // Actualizar presupuesto si aplica
    await _actualizarPresupuesto(transaccion);
    
    // Verificar alertas
    await _verificarAlertas(transaccion);
  }
  
  Future<void> _actualizarSaldos(Transaccion t) async {
    final cuenta = await db.getCuenta(t.cuentaId);
    
    switch (t.tipo) {
      case TipoTransaccion.ingreso:
        cuenta.saldo += t.monto;
        break;
      case TipoTransaccion.gasto:
        cuenta.saldo -= t.monto;
        break;
      case TipoTransaccion.transferencia:
        cuenta.saldo -= t.monto;
        if (t.cuentaDestinoId != null) {
          final cuentaDestino = await db.getCuenta(t.cuentaDestinoId!);
          cuentaDestino.saldo += t.monto;
          await db.updateCuenta(cuentaDestino);
        }
        break;
    }
    
    await db.updateCuenta(cuenta);
  }
  
  Future<void> _actualizarPresupuesto(Transaccion t) async {
    if (t.tipo != TipoTransaccion.gasto) return;
    
    final presupuesto = await db.getPresupuestoActivo(
      t.usuarioId,
      t.categoriaId,
    );
    
    if (presupuesto != null) {
      presupuesto.montoGastado += t.monto;
      await db.updatePresupuesto(presupuesto);
      
      // Verificar si se excedió
      if (presupuesto.excedido || presupuesto.cercaLimite) {
        await notificationService.enviarAlerta(
          titulo: "Presupuesto ${presupuesto.categoria.nombre}",
          mensaje: presupuesto.mensaje,
        );
      }
    }
  }
  
  Future<void> _verificarAlertas(Transaccion t) async {
    // Alertas de gastos inusuales
    if (t.tipo == TipoTransaccion.gasto && t.monto > 500000) {
      await notificationService.enviarAlerta(
        titulo: "Gasto grande detectado",
        mensaje: "Gastaste \$${t.monto.toStringAsFixed(0)} en ${t.categoria.nombre}",
      );
    }
    
    // Alerta de saldo bajo
    final cuenta = await db.getCuenta(t.cuentaId);
    if (cuenta.saldo < 100000 && cuenta.tipo == TipoCuenta.banco) {
      await notificationService.enviarAlerta(
        titulo: "Saldo bajo",
        mensaje: "${cuenta.nombre}: \$${cuenta.saldo.toStringAsFixed(0)}",
      );
    }
  }
}

// ============================================
// SERVICIO DE REPORTES
// ============================================

class ReporteService {
  final Database db;
  
  // Generar resumen mensual
  Future<ResumenMensual> generarResumenMes(
    String usuarioId,
    DateTime mes,
  ) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0);
    
    final transacciones = await db.getTransacciones(
      usuarioId: usuarioId,
      desde: inicio,
      hasta: fin,
    );
    
    final ingresos = transacciones
      .where((t) => t.tipo == TipoTransaccion.ingreso)
      .toList();
      
    final gastos = transacciones
      .where((t) => t.tipo == TipoTransaccion.gasto)
      .toList();
    
    return ResumenMensual(
      mes: mes,
      ingresos: ingresos,
      gastos: gastos,
    );
  }
  
  // Comparar con mes anterior
  Future<Comparacion> compararConMesAnterior(
    String usuarioId,
    DateTime mes,
  ) async {
    final actual = await generarResumenMes(usuarioId, mes);
    final anterior = await generarResumenMes(
      usuarioId,
      DateTime(mes.year, mes.month - 1),
    );
    
    return Comparacion(
      actual: actual,
      anterior: anterior,
    );
  }
  
  // Generar insights automáticos
  Future<List<Insight>> generarInsights(
    String usuarioId,
  ) async {
    final insights = <Insight>[];
    
    // Insight 1: Categoría con mayor aumento
    final comparacion = await compararConMesAnterior(
      usuarioId,
      DateTime.now(),
    );
    
    final aumentos = comparacion.cambiosPorCategoria
      .where((cat, cambio) => cambio > 0)
      .entries
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (aumentos.isNotEmpty) {
      final mayor = aumentos.first;
      insights.add(Insight(
        tipo: TipoInsight.alerta,
        titulo: "Aumento en ${mayor.key}",
        mensaje: "Gastaste \$${mayor.value.toStringAsFixed(0)} más que el mes pasado",
        accion: "Ver detalles",
      ));
    }
    
    // Insight 2: Meta cercana
    final metas = await db.getMetas(usuarioId);
    for (var meta in metas) {
      if (meta.progreso >= 90 && meta.progreso < 100) {
        insights.add(Insight(
          tipo: TipoInsight.motivacion,
          titulo: "¡Casi logras tu meta!",
          mensaje: "${meta.nombre}: ${meta.progreso.toStringAsFixed(0)}% completado",
          accion: "Ver meta",
        ));
      }
    }
    
    // Insight 3: Racha de ahorro
    final rachaAhorro = await _calcularRachaAhorro(usuarioId);
    if (rachaAhorro >= 3) {
      insights.add(Insight(
        tipo: TipoInsight.celebracion,
        titulo: "¡Racha de ahorro!",
        mensaje: "Has ahorrado $rachaAhorro meses seguidos",
        accion: null,
      ));
    }
    
    return insights;
  }
}

// ============================================
// SERVICIO DE ASISTENTE IA (FINA)
// ============================================

class FinaAsistenteService {
  final Database db;
  final ReporteService reporteService;
  
  Future<String> responderConsulta(
    String usuarioId,
    String pregunta,
  ) async {
    // Obtener contexto del usuario
    final contexto = await _obtenerContexto(usuarioId);
    
    // Analizar tipo de pregunta
    final tipo = _clasificarPregunta(pregunta);
    
    switch (tipo) {
      case TipoPregunta.patrimonio:
        return _responderPatrimonio(contexto);
      case TipoPregunta.gastos:
        return _responderGastos(contexto, pregunta);
      case TipoPregunta.ahorro:
        return _responderAhorro(contexto);
      case TipoPregunta.presupuesto:
        return _responderPresupuesto(contexto);
      case TipoPregunta.meta:
        return _responderMeta(contexto, pregunta);
      default:
        return _respuestaGenerica();
    }
  }
  
  Future<Map<String, dynamic>> _obtenerContexto(String usuarioId) async {
    final resumenMes = await reporteService.generarResumenMes(
      usuarioId,
      DateTime.now(),
    );
    
    final cuentas = await db.getCuentas(usuarioId);
    final totalActivos = cuentas.fold(0.0, (sum, c) => sum + c.saldo);
    
    return {
      'resumen_mes': resumenMes,
      'total_activos': totalActivos,
      'usuario_id': usuarioId,
    };
  }
  
  String _responderPatrimonio(Map<String, dynamic> contexto) {
    final totalActivos = contexto['total_activos'] as double;
    final resumen = contexto['resumen_mes'] as ResumenMensual;
    
    return """
    💰 TU PATRIMONIO ACTUAL
    
    Lo que tienes: \$${totalActivos.toStringAsFixed(0)}
    
    Este mes:
    • Recibiste: \$${resumen.totalIngresos.toStringAsFixed(0)}
    • Gastaste: \$${resumen.totalGastos.toStringAsFixed(0)}
    • Ahorraste: \$${resumen.ahorro.toStringAsFixed(0)} (${resumen.tasaAhorro.toStringAsFixed(1)}%)
    
    ${resumen.ahorro > 0 
      ? "✅ Vas por buen camino"
      : "⚠️ Revisa tus gastos"}
    """;
  }
}
```

### 8.3 Interfaz de Usuario - Componentes

```dart
// ============================================
// WIDGET: TARJETA DE BALANCE
// ============================================

class BalanceCard extends StatelessWidget {
  final double totalActivos;
  final double totalPasivos;
  final double cambioMensual;
  
  @override
  Widget build(BuildContext context) {
    final patrimonio = totalActivos - totalPasivos;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "💰 Tu Balance Personal",
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            
            // Lo que tienes
            _buildRow(
              "Lo que tienes",
              totalActivos,
              Colors.green,
            ),
            
            // Lo que debes
            _buildRow(
              "Lo que debes",
              totalPasivos,
              Colors.red,
            ),
            
            Divider(),
            
            // Patrimonio neto
            _buildRow(
              "Tus ahorros netos",
              patrimonio,
              Colors.blue,
              isTotal: true,
            ),
            
            // Cambio mensual
            if (cambioMensual != 0) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    cambioMensual > 0 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                    color: cambioMensual > 0 
                      ? Colors.green 
                      : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${cambioMensual > 0 ? '+' : ''}\$${cambioMensual.abs().toStringAsFixed(0)} vs mes pasado",
                    style: TextStyle(
                      color: cambioMensual > 0 
                        ? Colors.green 
                        : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRow(
    String label,
    double monto,
    Color color,
    {bool isTotal = false}
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "\$${monto.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// WIDGET: LISTA DE TRANSACCIONES
// ============================================

class TransaccionesLista extends StatelessWidget {
  final List<Transaccion> transacciones;
  final Function(Transaccion)? onTap;
  
  @override
  Widget build(BuildContext context) {
    if (transacciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No hay movimientos aún"),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _navegarAgregarTransaccion(context),
              child: Text("Agregar el primero"),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: transacciones.length,
      itemBuilder: (context, index) {
        final t = transacciones[index];
        return TransaccionTile(
          transaccion: t,
          onTap: () => onTap?.call(t),
        );
      },
    );
  }
}

class TransaccionTile extends StatelessWidget {
  final Transaccion transaccion;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    final esIngreso = transaccion.tipo == TipoTransaccion.ingreso;
    final color = esIngreso ? Colors.green : Colors.red;
    final icono = esIngreso ? Icons.arrow_downward : Icons.arrow_upward;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Text(
          transaccion.categoria.emoji,
          style: TextStyle(fontSize: 24),
        ),
      ),
      title: Text(transaccion.categoria.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaccion.descripcion.isNotEmpty)
            Text(transaccion.descripcion),
          Text(
            DateFormat('d MMM yyyy').format(transaccion.fecha),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${esIngreso ? '+' : '-'}\$${transaccion.monto.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Icon(icono, color: color, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}
```

---

## 9. Educación Financiera Integrada

### 9.1 Tutoriales Interactivos

**A. Tutorial Inicial (Onboarding)**

```dart
class TutorialInicial extends StatefulWidget {
  @override
  _TutorialInicialState createState() => _TutorialInicialState();
}

class _TutorialInicialState extends State<TutorialInicial> {
  int paginaActual = 0;
  
  final pasos = [
    TutorialPaso(
      titulo: "¡Bienvenido!",
      descripcion: """
      Finanzas Familiares te ayuda a:
      
      ✅ Controlar tus gastos
      ✅ Alcanzar tus metas de ahorro
      ✅ Tomar mejores decisiones financieras
      
      Todo de forma simple y visual.
      """,
      imagen: "assets/onboarding_1.png",
    ),
    TutorialPaso(
      titulo: "Registra tus cuentas",
      descripcion: """
      Empieza agregando tus cuentas bancarias,
      efectivo e inversiones.
      
      💡 No te preocupes, toda tu información
      está segura y encriptada.
      """,
      imagen: "assets/onboarding_2.png",
    ),
    TutorialPaso(
      titulo: "Anota tus movimientos",
      descripcion: """
      Cada vez que gastes o recibas dinero,
      anótalo en la app.
      
      📊 Así sabrás exactamente en qué
      se va tu dinero.
      """,
      imagen: "assets/onboarding_3.png",
      accion: () => _mostrarEjemploTransaccion(),
    ),
    TutorialPaso(
      titulo: "Crea presupuestos",
      descripcion: """
      Define cuánto quieres gastar en cada
      categoría cada mes.
      
      ⚠️ Te avisaremos si te estás pasando.
      """,
      imagen: "assets/onboarding_4.png",
    ),
    TutorialPaso(
      titulo: "Alcanza tus metas",
      descripcion: """
      Define metas de ahorro y sigue tu progreso.
      
      🎯 Vacaciones, carro nuevo, fondo de
      emergencia... ¡Tú decides!
      """,
      imagen: "assets/onboarding_5.png",
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: pasos.length,
                onPageChanged: (index) {
                  setState(() => paginaActual = index);
                },
                itemBuilder: (context, index) {
                  return _buildPagina(pasos[index]);
                },
              ),
            ),
            _buildIndicadores(),
            _buildBotones(),
          ],
        ),
      ),
    );
  }
}
```

### 9.2 Consejos Contextuales

```dart
class ConsejeroFinanciero {
  // Genera consejos basados en el contexto del usuario
  static String generarConsejo(ContextoUsuario contexto) {
    // Detectar patrones y problemas
    if (contexto.tasaAhorro < 10) {
      return _consejoAhorroB ajo();
    }
    
    if (contexto.gastosEntretenimiento > contexto.ingresos * 0.15) {
      return _consejoEntretenimientoAlto();
    }
    
    if (contexto.deudas > contexto.ingresos * 3) {
      return _consejoDeudaAlta();
    }
    
    if (contexto.sinFondoEmergencia) {
      return _consejoFondoEmergencia();
    }
    
    // Si todo va bien, dar consejo de optimización
    return _consejoOptimizacion();
  }
  
  static String _consejoAhorroBajo() {
    return """
    💡 CONSEJO: Aumenta tu ahorro
    
    Actualmente ahorras menos del 10% de tus ingresos.
    
    🎯 Meta: Llegar al 20%
    
    Ideas para lograrlo:
    • Reduce gastos en entretenimiento
    • Cocina más en casa (ahorra en restaurantes)
    • Cancela suscripciones que no uses
    • Automatiza tu ahorro (apenas cobres, aparta)
    
    💰 Pequeños cambios = Grandes resultados
    """;
  }
  
  static String _consejoEntretenimientoAlto() {
    return """
    💡 CONSEJO: Revisa tu entretenimiento
    
    Estás gastando mucho en salidas y diversión.
    
    No se trata de no disfrutar, sino de ser inteligente:
    
    ✅ Busca alternativas gratuitas o baratas
    ✅ Aprovecha días de descuento
    ✅ Prepara comida antes de salir
    ✅ Establece un presupuesto fijo mensual
    
    🎯 Objetivo: Divertirte sin descuidar tus finanzas
    """;
  }
}
```

### 9.3 Logros y Gamificación

```dart
class SistemaLogros {
  static final logrosDisponibles = [
    Logro(
      id: "primer_registro",
      titulo: "🎉 Primer paso",
      descripcion: "Registraste tu primera transacción",
      puntos: 10,
    ),
    Logro(
      id: "semana_completa",
      titulo: "📅 Disciplinado",
      descripcion: "Registraste gastos todos los días por una semana",
      puntos: 50,
    ),
    Logro(
      id: "ahorro_20",
      titulo: "💰 Ahorrador",
      descripcion: "Ahorraste el 20% de tus ingresos",
      puntos: 100,
    ),
    Logro(
      id: "meta_alcanzada",
      titulo: "🎯 Meta cumplida",
      descripcion: "Alcanzaste una meta de ahorro",
      puntos: 150,
    ),
    Logro(
      id: "sin_deudas",
      titulo: "🏆 Libre de deudas",
      descripcion: "Pagaste todas tus deudas",
      puntos: 500,
    ),
  ];
  
  static Future<void> verificarLogros(String usuarioId) async {
    // Lógica para otorgar logros
  }
}
```

---

## 10. Casos de Uso Prácticos

### Caso 1: María - Empleada con Salario Fijo

**Perfil:**

- Ingresos: $3,000,000/mes
- Gastos fijos: $2,000,000
- Objetivo: Ahorrar para vacaciones

**Configuración inicial:**
```dart
// Cuentas

- Bancolombia Ahorros: $1,500,000
- Efectivo: $200,000

// Presupuesto mensual

- Arriendo: $1,000,000
- Servicios: $300,000
- Transporte: $200,000
- Alimentación: $600,000
- Entretenimiento: $300,000
- Ahorro: $600,000

// Meta

- Vacaciones en Cartagena
- Objetivo: $4,000,000
- Plazo: 7 meses
- Ahorro mensual necesario: $571,429
```

**Uso diario:**
```

1. Cada compra → Anotar inmediatamente
2. Fin de semana → Revisar gastos
3. Fin de mes → Ver resumen y ajustar
```

### Caso 2: Juan - Trabajador Independiente

**Perfil:**

- Ingresos variables: $2,000,000 - $5,000,000
- Gastos irregulares
- Objetivo: Estabilidad financiera

**Configuración especial:**
```dart
// Cuentas separadas

- Cuenta ingresos: Recibe todo
- Cuenta gastos: $2,500,000 fijo mensual
- Cuenta ahorros: Excedentes

// Regla de separación
Al recibir pago:

1. Apartar 30% para impuestos
2. Transferir $2,500,000 a gastos
3. Resto a ahorros

// Presupuesto conservador
Basado en ingreso mínimo: $2,000,000
```

### Caso 3: Familia López - Control Conjunto

**Perfil:**

- 2 ingresos: $4,000,000 total
- Gastos compartidos y personales
- Objetivo: Educación hijos

**Configuración familiar:**
```dart
// Cuentas compartidas

- Cuenta común: Gastos compartidos
- Cuentas personales: Gastos individuales

// División de gastos

- Vivienda: Compartido 50/50
- Servicios: Compartido
- Mercado: Compartido
- Entretenimiento: Personal

// Meta familiar

- Educación universitaria
- 15 años de ahorro
- Estrategia: Inversiones automáticas
```

---

## Conclusión

Este documento establece las bases para un sistema de finanzas personales **amigable, educativo y útil** que:

✅ **Usa terminología simple** sin sacrificar rigor  
✅ **Aplica principios contables** de forma invisible  
✅ **Educa mientras se usa** sin ser pedagógico  
✅ **Es flexible y personalizable** según cada usuario  
✅ **Motiva y guía** hacia mejores hábitos financieros  

**Próximos pasos de implementación:**

1. Prototipar interfaz con terminología amigable
2. Implementar categorías y presupuestos default
3. Crear tutoriales interactivos
4. Desarrollar sistema de insights automáticos
5. Integrar asistente IA (Fina)
6. Probar con usuarios reales
7. Iterar según feedback

---

**Versión:** 1.0  
**Fecha:** 4 de enero de 2026  
**Próxima revisión:** Marzo 2026
