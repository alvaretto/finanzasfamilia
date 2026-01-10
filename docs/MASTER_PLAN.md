# Plan Maestro - Finanzas Familiares AS

**Versión:** 2.0
**Fecha:** 2026-01-09
**Objetivo:** Refactorización Arquitectónica + MVP en Play Store/App Store

---

## Visión del Producto

Aplicación de finanzas personales **Offline-First** con sincronización híbrida, diseñada para el contexto financiero colombiano. Motor contable de partida doble oculto tras una interfaz simple.

### Principios de Diseño

1. **Offline-First**: Funciona 100% sin internet
2. **Sync Transparente**: Sincroniza automáticamente cuando hay conexión
3. **Simplicidad**: UI simple, contabilidad profesional invisible
4. **Contexto Local**: Adaptado a Colombia (Nequi, DaviPlata, 4x1000)
5. **Clean Architecture**: Separación clara de capas y responsabilidades

---

## Estado Actual

| Métrica | Valor |
|---------|-------|
| Versión | 2.8 |
| Fase Actual | Refactorización Arquitectónica |
| Tests | 465+ pasando |
| Cobertura | ~85% |

### Funcionalidades Implementadas (29 Fases)

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
| Metas de Ahorro | ✅ | 27 |
| Adjuntos y OCR | ✅ | 28 |
| Modo Familiar | ✅ | 29 |

---

## Roadmap de Refactorización Arquitectónica

### Contexto

Tras completar 29 fases de desarrollo funcional, se identificaron 12 problemas arquitectónicos críticos que requieren atención antes de continuar con nuevas features. Esta refactorización mejora mantenibilidad, testabilidad y escalabilidad.

### Problemas Identificados

| # | Problema | Severidad | Estado |
|---|----------|-----------|--------|
| 1 | Fat Providers (lógica de negocio en providers) | CRÍTICO | ✅ Resuelto |
| 2 | Proliferación de providers (21 archivos) | ALTO | Pendiente |
| 3 | Duplicación Dashboard/Charts/Reports | ALTO | Pendiente |
| 4 | Domain depende de Data (violación Clean Arch) | MEDIO | Pendiente |
| 5 | Riverpod: mezcla de estilos (generated vs manual) | BAJO | Pendiente |
| 6 | Modelos mezclados en archivos de providers | ALTO | ✅ Resuelto |
| 7 | Servicios mal ubicados (application vs domain) | MEDIO | Pendiente |
| 8 | Providers pass-through innecesarios | BAJO | Pendiente |
| 9 | Tests acoplados a implementación | MEDIO | Pendiente |
| 10 | Falta de interfaces/abstracciones | MEDIO | Pendiente |
| 11 | Imports circulares potenciales | BAJO | Pendiente |
| 12 | Documentación técnica desactualizada | BAJO | Pendiente |

---

### ~~Fase R1: Extraer Lógica de Negocio~~ ✅ COMPLETADA
**Objetivo:** Mover lógica de negocio de providers a services de dominio
**Completado:** 2026-01-09

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| R1.1 | Crear `lib/domain/entities/dashboard/` | ✅ |
| R1.2 | Crear entidades: CategoryExpense, BudgetAlert, etc. | ✅ |
| R1.3 | Crear `DashboardService` con lógica pura | ✅ |
| R1.4 | Refactorizar `dashboard_provider.dart` | ✅ |
| R1.5 | Unificar `IndicatorStatus` en domain | ✅ |

**Resultados:**
- `dashboard_provider.dart`: 395 → 109 líneas (-72%)
- Nuevos archivos en `lib/domain/entities/dashboard/`:
  - `category_expense.dart`
  - `budget_alert.dart`
  - `expense_group.dart`
  - `month_summary.dart`
  - `dashboard_summary.dart`
  - `indicator_status.dart`
  - `dashboard.dart` (barrel)
- Nuevo servicio: `lib/domain/services/dashboard_service.dart`
- Tests: 465+ pasando

---

### Fase R2: Consolidar Duplicación
**Objetivo:** Eliminar código duplicado entre Dashboard, Charts y Reports
**Prioridad:** ALTA

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| R2.1 | Identificar lógica duplicada | ⏳ |
| R2.2 | Crear servicios compartidos | ⏳ |
| R2.3 | Refactorizar ChartService para usar DashboardService | ⏳ |
| R2.4 | Refactorizar ReportsService para usar DashboardService | ⏳ |
| R2.5 | Eliminar código redundante | ⏳ |

**Archivos a revisar:**
- `lib/application/providers/chart_provider.dart`
- `lib/application/services/reports_service.dart`
- `lib/domain/services/dashboard_service.dart`

---

### Fase R3: Limpiar Providers Pass-Through
**Objetivo:** Eliminar providers que solo re-exponen DAOs
**Prioridad:** MEDIA

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| R3.1 | Identificar providers pass-through | ⏳ |
| R3.2 | Evaluar si agregan valor | ⏳ |
| R3.3 | Eliminar o consolidar innecesarios | ⏳ |
| R3.4 | Actualizar imports en código cliente | ⏳ |

**Candidatos:**
- Providers de DAOs que no agregan lógica
- Providers de servicios singleton

---

### Fase R4: Reorganizar Capas (Clean Architecture)
**Objetivo:** Cumplir con la regla de dependencias (Domain no depende de Data)
**Prioridad:** MEDIA

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| R4.1 | Crear interfaces de repositorio en domain | ⏳ |
| R4.2 | Implementar repositorios en data | ⏳ |
| R4.3 | Actualizar servicios para usar interfaces | ⏳ |
| R4.4 | Mover servicios mal ubicados | ⏳ |

**Estructura objetivo:**
```
domain/
├── entities/        # Modelos puros
├── repositories/    # Interfaces (abstract)
└── services/        # Lógica de negocio (usa interfaces)

data/
├── local/           # Drift DAOs
├── remote/          # Supabase
└── repositories/    # Implementaciones concretas
```

---

### Fase R5: Actualizar Tests y Documentación
**Objetivo:** Tests desacoplados y documentación actualizada
**Prioridad:** BAJA

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| R5.1 | Agregar tests unitarios para DashboardService | ⏳ |
| R5.2 | Actualizar tests existentes | ⏳ |
| R5.3 | Actualizar CLAUDE.md con nueva arquitectura | ⏳ |
| R5.4 | Actualizar docs/ARCHITECTURE.md | ⏳ |
| R5.5 | Generar diagrama de dependencias actualizado | ⏳ |

---

## Roadmap Post-Refactorización

### Fase 30: Widget y Accesos Rápidos
**Objetivo:** Acceso desde home screen
**Prioridad:** BAJA

| Tarea | Descripción |
|-------|-------------|
| 30.1 | Widget de saldo total (Android/iOS) |
| 30.2 | Quick Actions (3D Touch / Long Press) |
| 30.3 | Shortcut para "Nueva Transacción" |

### Fase 31: Internacionalización
**Objetivo:** Soporte multi-idioma
**Prioridad:** MEDIA

| Tarea | Descripción |
|-------|-------------|
| 31.1 | Extraer strings a archivos de localización |
| 31.2 | Implementar flutter_localizations |
| 31.3 | Traducir a inglés |
| 31.4 | Formato de moneda configurable |

### Fase 32: Temas y Personalización
**Objetivo:** Dark mode y personalización visual
**Prioridad:** BAJA

| Tarea | Descripción |
|-------|-------------|
| 32.1 | Implementar tema oscuro |
| 32.2 | Selector de tema en configuración |
| 32.3 | Colores personalizables para categorías |

---

## Leyenda de Estimaciones

| Símbolo | Tiempo | Descripción |
|---------|--------|-------------|
| S | 1-2 horas | Tarea pequeña, cambio puntual |
| M | 2-4 horas | Tarea mediana, nuevo componente |
| L | 4-8 horas | Tarea grande, feature completo |
| XL | 1-2 días | Feature complejo, múltiples componentes |

---

## Criterios de Aceptación

### Para marcar una fase como COMPLETADA:

1. **Código:** Todos los archivos implementados
2. **Tests:** Sin regresiones (todos los tests pasan)
3. **Análisis:** Sin warnings de análisis estático
4. **Docs:** CLAUDE.md actualizado con changelog
5. **Git:** Commit con mensaje descriptivo

---

## Métricas de Éxito

| Métrica | Objetivo | Actual |
|---------|----------|--------|
| Crash-free rate | > 99% | N/A |
| App size (Android) | < 100 MB | ~100 MB |
| Cold start time | < 2 segundos | ~1.5s |
| Tests pasando | 100% | ✅ |
| Líneas por provider | < 150 | ✅ (dashboard: 109) |

---

## Arquitectura Objetivo

### Flujo de Datos
```
UI (presentation)
    ↓ usa
Providers (application)
    ↓ orquesta
Services (domain)
    ↓ usa interfaces de
Repositories (domain/repositories) ← interfaces abstractas
    ↑ implementados por
DAOs (data/local) + Remote (data/remote)
```

### Regla de Dependencias
```
presentation → application → domain ← data
                              ↑
                    (domain NO depende de data)
```

---

## Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2026-01-09 | Plan inicial definido |
| 1.1-1.9 | 2026-01-09 | Fases 22-29 completadas |
| 2.0 | 2026-01-09 | **Nueva visión:** Refactorización Arquitectónica |
| 2.0.1 | 2026-01-09 | Fase R1 completada (DashboardService) |

---

*Documento mantenido por el equipo de desarrollo. Actualizar después de cada fase completada.*
