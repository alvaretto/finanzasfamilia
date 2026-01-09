# Plan Maestro - Finanzas Familiares AS

**Versión:** 1.0
**Fecha:** 2026-01-09
**Objetivo:** MVP en Play Store/App Store

---

## Visión del Producto

Aplicación de finanzas personales **Offline-First** con sincronización híbrida, diseñada para el contexto financiero colombiano. Motor contable de partida doble oculto tras una interfaz simple.

### Principios de Diseño

1. **Offline-First**: Funciona 100% sin internet
2. **Sync Transparente**: Sincroniza automáticamente cuando hay conexión
3. **Simplicidad**: UI simple, contabilidad profesional invisible
4. **Contexto Local**: Adaptado a Colombia (Nequi, DaviPlata, 4x1000)

---

## Estado Actual

| Métrica | Valor |
|---------|-------|
| Versión | 2.4 |
| Fase Actual | 26 Completada |
| Tests | 430+ pasando |
| Cobertura | ~85% |

### Funcionalidades Implementadas

| Feature | Estado | Fase |
|---------|--------|------|
| Auth (Google + Invitado) | ✅ | 16 |
| Onboarding | ✅ | 17 |
| Dashboard | ✅ | 6-13 |
| CRUD Cuentas | ✅ | 6-13 |
| CRUD Categorías (jerárquicas) | ✅ | 19 |
| CRUD Transacciones | ✅ | 21 |
| Motor Contable (Partida Doble) | ✅ | 3.5 |
| Presupuestos + Semáforos | ✅ | 20 |
| Transacciones Recurrentes | ✅ | 18 |
| Reportes Financieros | ✅ | 14 |
| Asistente IA "Fina" | ✅ | 15 |
| Export (CSV/Excel/PDF) | ✅ | 4 |
| Backup Local | ✅ | 5 |
| Pulido UI/UX | ✅ | 22 |
| Sincronización PowerSync | ✅ | 23 |
| Preparación Store | ✅ | 24 |
| Notificaciones Locales | ✅ | 25 |
| Gráficos Avanzados | ✅ | 26 |

---

## Roadmap MVP

### ~~Fase 22: Pulido UI/UX (Pre-Release)~~ ✅ COMPLETADA
**Objetivo:** App lista para usuarios reales
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| 22.1 | Revisión de estados vacíos en todas las pantallas | ✅ |
| 22.2 | Manejo de errores con SnackBars consistentes | ✅ |
| 22.3 | Loading states en formularios | ✅ |
| 22.4 | Validaciones de formularios completas | ✅ |
| 22.5 | Feedback háptico en acciones importantes | ✅ |
| 22.6 | Error handling en splash/onboarding | ✅ |
| 22.7 | Documentación de patrones de testing | ✅ |

**Entregables:**
- ✅ App visualmente pulida
- ✅ UX consistente en todos los flujos
- ✅ Sin crashes ni estados rotos

---

### ~~Fase 23: Sincronización PowerSync~~ ✅ COMPLETADA
**Objetivo:** Backup automático y multi-dispositivo
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| 23.1 | Configurar PowerSync en Supabase | ✅ |
| 23.2 | Implementar `SupabaseConnector` completo | ✅ |
| 23.3 | Sync Rules por usuario | ✅ |
| 23.4 | UI de estado de sincronización | ✅ |
| 23.5 | Manejo de conflictos (Last-Write-Wins) | ✅ |
| 23.6 | Tests de sincronización | ✅ |

**Implementaciones clave:**
- `ConnectivityNotifier`: Monitoreo de red con `connectivity_plus`
- `SyncStatusIndicator`: Widget visual con iconos cloud, spinner y colores
- `_SyncDetailsSheet`: Bottom sheet con detalles de conexión y errores
- `SupabaseConnector`: Callbacks para errores y completado de sync
- `PowerSyncDatabaseManager`: Integración con statusStream
- Auto-sync al reconectar a internet
- 18 tests nuevos (9 connectivity + 9 sync_indicator)

**Entregables:**
- ✅ Datos respaldados en Supabase
- ✅ Sync automático en background
- ✅ Indicador visual de estado

---

### ~~Fase 24: Preparación Store~~ ✅ COMPLETADA
**Objetivo:** Publicar en Google Play y App Store
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| 24.1 | App Icon y Splash Screen finales | ✅ |
| 24.2 | Screenshots para stores | ✅ |
| 24.3 | Privacy Policy y Terms of Service | ✅ |
| 24.4 | Configurar Firebase Crashlytics | ✅ |
| 24.5 | Configurar Firebase Analytics | ✅ |
| 24.6 | Build de release (Android) | ✅ |
| 24.7 | Build de release (iOS) | ⏳ Pendiente |
| 24.8 | Ficha de tienda (descripción, keywords) | ✅ |

**Implementaciones:**
- App Icon personalizado en todas las resoluciones (mipmap-*)
- Privacy Policy y Delete Account pages (docs/*.html)
- Firebase Crashlytics + Analytics configurado
- Build APK/AAB de release funcional
- Ficha de tienda preparada

**Entregables:**
- ✅ APK/AAB firmado
- ⏳ IPA firmado (pendiente)
- ✅ Listado en stores preparado

---

### ~~Fase 25: Notificaciones~~ ✅ COMPLETADA
**Objetivo:** Recordatorios proactivos
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| 25.1 | Notificaciones locales (flutter_local_notifications) | ✅ |
| 25.2 | Alerta de presupuesto al 80% y 100% | ✅ |
| 25.3 | Recordatorio de transacciones recurrentes | ✅ |
| 25.4 | Recordatorio de registro diario (opcional) | ✅ |
| 25.5 | Configuración de preferencias de notificación | ✅ |

**Implementaciones:**
- `NotificationService`: Servicio singleton con flutter_local_notifications ^18.0.1
  - Alertas de presupuesto con IDs únicos (budgetWarningId=1000, budgetExceededId=1001)
  - Recordatorios recurrentes (recurringReminderBaseId=2000)
  - Recordatorio diario configurable (dailyReminderBaseId=3000)
  - Canales Android: budget_alerts, recurring_reminders, daily_reminder
- `NotificationProvider`: Estado de configuración con Riverpod AsyncNotifier
- `BudgetAlertProvider`: Verificador automático de umbrales de presupuesto
- `NotificationSettingsScreen`: UI completa con switches y selector de hora
- 11 tests nuevos (4 service + 7 screen), 3 skipped (plugin nativo)

**Entregables:**
- ✅ Alertas de presupuesto funcionando
- ✅ Recordatorios programables
- ✅ Configuración de preferencias en pantalla

---

### ~~Fase 26: Gráficos Avanzados~~ ✅ COMPLETADA
**Objetivo:** Visualización de tendencias
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| 26.1 | Gráfico de gastos por categoría (pie chart animado) | ✅ |
| 26.2 | Tendencia mensual de ingresos vs gastos (line chart) | ✅ |
| 26.3 | Comparativo mes actual vs anterior | ✅ |
| 26.4 | Proyección de saldo a fin de mes | ⏳ Post-MVP |
| 26.5 | Heat map de días con más gastos | ⏳ Post-MVP |

**Implementaciones:**
- `ChartService`: Servicio de cálculos para gráficos financieros
  - `getExpensesByCategory()`: Agrupa gastos por categoría con porcentajes
  - `getMonthlyTrend()`: Tendencia de ingresos vs gastos (N meses)
  - `getMonthComparison()`: Compara mes actual vs anterior
  - `getTopExpenseCategories()`: Top N categorías de gasto
- Modelos: `CategoryExpenseData`, `MonthlyTrendData`, `PeriodComparison`
- `ExpensePieChart`: Gráfico de pie interactivo con leyenda
- `MonthlyTrendChart`: Gráfico de línea con 3 series (ingresos, gastos, balance)
- `MonthComparisonCard`: Tarjeta comparativa con íconos de tendencia
- `StatisticsScreen`: 3 tabs (Gastos, Tendencia, Comparar)
- Providers: `chartService`, `currentMonthExpenses`, `monthlyTrend`, `monthComparison`
- Botón de estadísticas en Dashboard AppBar
- 26 tests nuevos (9 service + 11 widgets + 7 screen)

**Entregables:**
- ✅ Pie chart de gastos por categoría
- ✅ Line chart de tendencias mensuales
- ✅ Comparativo mes actual vs anterior
- ✅ Pantalla de estadísticas integrada

---

## Roadmap Post-MVP

### Fase 27: Metas de Ahorro
**Objetivo:** Gamificación del ahorro
**Prioridad:** MEDIA

| Tarea | Descripción |
|-------|-------------|
| 27.1 | CRUD de metas (nombre, monto objetivo, fecha límite) |
| 27.2 | Asignar transacciones a metas |
| 27.3 | Progress bar visual por meta |
| 27.4 | Celebración al alcanzar meta |
| 27.5 | Sugerencias de ahorro de "Fina" |

---

### Fase 28: Adjuntos y OCR
**Objetivo:** Digitalizar recibos
**Prioridad:** BAJA

| Tarea | Descripción |
|-------|-------------|
| 28.1 | Adjuntar fotos a transacciones |
| 28.2 | Galería de recibos |
| 28.3 | OCR para extraer monto automáticamente |
| 28.4 | Almacenamiento en Supabase Storage |

---

### Fase 29: Modo Familiar
**Objetivo:** Finanzas compartidas
**Prioridad:** BAJA (v2.0)

| Tarea | Descripción |
|-------|-------------|
| 29.1 | Modelo de "Familia" con miembros |
| 29.2 | Roles: Administrador, Miembro, Viewer |
| 29.3 | Cuentas compartidas vs personales |
| 29.4 | Presupuestos familiares |
| 29.5 | Dashboard consolidado |

---

### Fase 30: Widget y Accesos Rápidos
**Objetivo:** Acceso desde home screen
**Prioridad:** BAJA

| Tarea | Descripción |
|-------|-------------|
| 30.1 | Widget de saldo total (Android/iOS) |
| 30.2 | Quick Actions (3D Touch / Long Press) |
| 30.3 | Shortcut para "Nueva Transacción" |

---

## Leyenda de Estimaciones

| Símbolo | Tiempo | Descripción |
|---------|--------|-------------|
| S | 1-2 horas | Tarea pequeña, cambio puntual |
| M | 2-4 horas | Tarea mediana, nuevo componente |
| L | 4-8 horas | Tarea grande, feature completo |
| XL | 1-2 días | Feature complejo, múltiples componentes |

---

## Criterios de Aceptación por Fase

### Para marcar una fase como COMPLETADA:

1. **Código:** Todos los archivos implementados
2. **Tests:** Cobertura mínima 80% para nuevos features
3. **UI:** Sin warnings de análisis estático
4. **Docs:** CLAUDE.md actualizado con changelog
5. **Git:** Commit con mensaje descriptivo

---

## Métricas de Éxito MVP

| Métrica | Objetivo |
|---------|----------|
| Crash-free rate | > 99% |
| App size (Android) | < 30 MB |
| Cold start time | < 2 segundos |
| Rating objetivo | > 4.5 estrellas |
| Tests pasando | 100% |

---

## Notas Técnicas

### PowerSync + Supabase

```
Usuario → App → Drift (SQLite local) → PowerSync → Supabase (Postgres)
                    ↑                      ↓
                    └──── Sync bidireccional ────┘
```

### Prioridad de Sync

1. Transacciones (crítico)
2. Cuentas y balances (crítico)
3. Categorías (importante)
4. Presupuestos (importante)
5. Preferencias (bajo)

---

## Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2026-01-09 | Plan inicial definido |
| 1.1 | 2026-01-09 | Fase 22 completada |
| 1.2 | 2026-01-09 | Fase 23 completada (PowerSync) |
| 1.3 | 2026-01-09 | Fase 24 completada (Preparación Store) |
| 1.4 | 2026-01-09 | Fase 25 completada (Notificaciones) |
| 1.5 | 2026-01-09 | Fase 26 completada (Gráficos Avanzados) |

---

*Documento mantenido por el equipo de desarrollo. Actualizar después de cada fase completada.*
