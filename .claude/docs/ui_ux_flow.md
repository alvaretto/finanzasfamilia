# UI/UX Flow - Finanzas Familiares v2

## Navigation Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Structure                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Auth Flow (No autenticado)                                     │
│  ├── Splash Screen                                              │
│  ├── Login Screen (Google Sign-In)                              │
│  └── Onboarding (Primera vez)                                   │
│                                                                 │
│  Main Flow (Autenticado)                                        │
│  ├── Bottom Navigation                                          │
│  │   ├── 🏠 Dashboard (Home)                                    │
│  │   ├── 💰 Transacciones                                       │
│  │   ├── 📊 Reportes                                            │
│  │   └── ⚙️ Configuración                                       │
│  │                                                              │
│  └── FAB: 💬 Asistente IA (Fina)                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Screen Flows

### 1. Auth Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Splash     │────▶│    Login     │────▶│  Onboarding  │
│              │     │              │     │              │
│  [Logo]      │     │ [Google]     │     │ • Cuentas    │
│  [Loading]   │     │ [Sign In]    │     │ • Categorías │
│              │     │              │     │ • Tutorial   │
└──────────────┘     └──────────────┘     └──────────────┘
       │                                         │
       │ (Si ya autenticado)                     │
       └─────────────────────────────────────────┴────▶ Dashboard
```

### 2. Dashboard

```
┌─────────────────────────────────────────┐
│  Finanzas Familiares           🔔  👤  │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Saldo Total                      │  │
│  │  $1,450,000 COP                   │  │
│  │  ▲ +$150,000 este mes             │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Lo que Tengo        Lo que Debo        │
│  ┌───────────┐       ┌───────────┐      │
│  │ $2,100,000│       │ $650,000  │      │
│  │ ▸ Nequi   │       │ ▸ Visa    │      │
│  │ ▸ Efectivo│       │ ▸ Préstamo│      │
│  └───────────┘       └───────────┘      │
│                                         │
│  Gastos del Mes                         │
│  ┌───────────────────────────────────┐  │
│  │  [Pie Chart]     Alimentación 35% │  │
│  │                  Transporte   20% │  │
│  │                  Servicios    18% │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Últimas Transacciones                  │
│  ┌───────────────────────────────────┐  │
│  │ 🛒 Mercado D1      -$85,000       │  │
│  │ ⛽ Gasolina        -$120,000      │  │
│  │ 💰 Salario        +$3,500,000     │  │
│  └───────────────────────────────────┘  │
│                                         │
│                              ┌────────┐ │
│                              │  💬   │ │
│                              └────────┘ │
├─────────────────────────────────────────┤
│  🏠      💰      📊      ⚙️            │
└─────────────────────────────────────────┘
```

### 3. Nueva Transacción (Bottom Sheet)

```
┌─────────────────────────────────────────┐
│  Nueva Transacción                  ✕   │
├─────────────────────────────────────────┤
│                                         │
│  Tipo:  [Gasto] [Ingreso] [Transfer]    │
│                                         │
│  Monto                                  │
│  ┌───────────────────────────────────┐  │
│  │  $ 85,000                         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Cuenta                                 │
│  ┌───────────────────────────────────┐  │
│  │  💳 Nequi                      ▼  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Categoría                              │
│  ┌───────────────────────────────────┐  │
│  │  🛒 Mercado > Frutas           ▼  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Descripción (opcional)                 │
│  ┌───────────────────────────────────┐  │
│  │  Frutas en D1                     │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Fecha: Hoy, 8 Ene 2026           📅   │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │          GUARDAR                  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 4. Asistente IA (Fina)

```
┌─────────────────────────────────────────┐
│  💬 Fina - Asistente Financiero    ✕   │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🤖 ¡Hola! Soy Fina, tu asistente │  │
│  │    financiero. Puedo ayudarte    │  │
│  │    con:                          │  │
│  │    • Análisis de gastos          │  │
│  │    • Consejos de ahorro          │  │
│  │    • Preguntas sobre tus datos   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 👤 ¿Cuánto gasté en mercado      │  │
│  │    este mes?                     │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🤖 En enero 2026 gastaste        │  │
│  │    **$385,000** en mercado:      │  │
│  │                                  │  │
│  │    | Categoría | Monto     |     │  │
│  │    |-----------|-----------|     │  │
│  │    | Frutas    | $85,000   |     │  │
│  │    | Cárnicos  | $180,000  |     │  │
│  │    | Lácteos   | $65,000   |     │  │
│  │    | Otros     | $55,000   |     │  │
│  │                                  │  │
│  │    💡 **Tip:** Tus gastos en     │  │
│  │    cárnicos aumentaron 15%       │  │
│  │    respecto al mes pasado.       │  │
│  └───────────────────────────────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────┐  ┌──┐ │
│  │ Escribe tu pregunta...      │  │➤│ │
│  └─────────────────────────────┘  └──┘ │
└─────────────────────────────────────────┘
```

### 5. Selector de Categorías (Jerárquico)

```
┌─────────────────────────────────────────┐
│  Seleccionar Categoría              ✕   │
├─────────────────────────────────────────┤
│  🔍 Buscar...                           │
├─────────────────────────────────────────┤
│                                         │
│  🍽️ Alimentación                    ▶   │
│     ├── 🛒 Mercado                  ▶   │
│     │     ├── 🍎 Frutas             ●   │
│     │     ├── 🥬 Verduras               │
│     │     ├── 🥩 Cárnicos               │
│     │     ├── 🥛 Lácteos                │
│     │     └── 🍿 Mecato                 │
│     ├── 🍴 Restaurantes                 │
│     └── 🛵 Domicilios                   │
│                                         │
│  🚗 Transporte                      ▶   │
│  💡 Servicios                       ▶   │
│  🏛️ Impuestos                       ▶   │
│  🎬 Entretenimiento                 ▶   │
│  🏥 Salud                           ▶   │
│                                         │
└─────────────────────────────────────────┘
```

## Color Scheme

```
Primary:     #2E7D32 (Green 800)    - Dinero, positivo
Secondary:   #1565C0 (Blue 800)     - Acciones, links
Error:       #C62828 (Red 800)      - Gastos, alertas
Background:  #FAFAFA                - Fondo claro
Surface:     #FFFFFF                - Cards

Income:      #4CAF50 (Green)
Expense:     #F44336 (Red)
Transfer:    #2196F3 (Blue)
```

## Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | < 600px | Single column, bottom nav |
| Tablet | 600-900px | Two columns, side nav |
| Desktop | > 900px | Three columns, expanded nav |

## Gestures

| Gesture | Action |
|---------|--------|
| Swipe left (transaction) | Editar |
| Swipe right (transaction) | Eliminar |
| Long press (category) | Opciones |
| Pull down (lists) | Refresh |
| FAB tap | Abrir chat IA |

## Loading States

```
┌─────────────────────────────────────────┐
│                                         │
│            ◠◡◠◡◠◡◠◡                     │
│         Cargando datos...               │
│                                         │
│         [░░░░░░░░░░] 45%                │
│                                         │
└─────────────────────────────────────────┘
```

## Empty States

```
┌─────────────────────────────────────────┐
│                                         │
│              📊                         │
│                                         │
│     No hay transacciones                │
│     este mes                            │
│                                         │
│     ┌───────────────────────┐           │
│     │  + Agregar primera    │           │
│     └───────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

## Offline Indicator

```
┌─────────────────────────────────────────┐
│  ⚠️ Sin conexión - Modo offline        │
└─────────────────────────────────────────┘
```
