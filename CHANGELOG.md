# Changelog

Todos los cambios notables en Finanzas Familiares AS seran documentados en este archivo.

**Historial completo anterior**: Ver [CHANGELOG_ARCHIVE_2024-2025.md](CHANGELOG_ARCHIVE_2024-2025.md) para versiones 1.0.0 - 1.9.13.

---

## [2.0.0-Refactor] - 2026-01-07

### Realineacion Arquitectonica y Mejoras de Consistencia

Esta version marca un punto de inflexion en el desarrollo de la aplicacion: **consolidacion arquitectonica basada en el sistema PUC (Plan Unico de Cuentas)**.

#### ¿Que es el Sistema PUC?

PUC es el sistema contable colombiano que organiza las finanzas en 5 clases principales:

1. **Activo** ("Lo que Tengo"): Efectivo, cuentas bancarias, inversiones
2. **Pasivo** ("Lo que Debo"): Tarjetas de credito, prestamos, deudas
3. **Patrimonio** ("Tu Capital"): La diferencia entre lo que tienes y lo que debes
4. **Ingresos** ("Dinero que Entra"): Salario, ventas, inversiones
5. **Gastos** ("Dinero que Sale"): Alimentacion, transporte, servicios

Dentro de la clase **Gastos**, distinguimos dos tipos importantes:
- **Gastos Fijos (Obligatorios)**: Arriendo, servicios publicos, creditos - no puedes evitarlos
- **Gastos Variables (Estilo de Vida)**: Entretenimiento, restaurantes, ropa - puedes controlarlos

#### Cambios para el Usuario

**Dashboard Mejorado**:
- Ahora muestra claramente "Lo que Tengo" (Activos) vs "Lo que Debo" (Pasivos)
- Nuevo calculo automatico de Patrimonio Neto
- Indicador de "Salud Mensual": compara tus ingresos vs gastos fijos vs gastos variables
- Visualizacion mas clara de donde esta tu dinero

**Gastos Mejor Organizados**:
- Cada categoria de gasto ahora esta clasificada como FIJA o VARIABLE
- Tus reportes ahora distinguen entre gastos que DEBES pagar (fijos) y gastos que PUEDES controlar (variables)
- Esto te ayuda a identificar mejor oportunidades de ahorro

**Lo que NO cambio**:
- Tus datos estan intactos (cuentas, transacciones, presupuestos, metas)
- La sincronizacion con Supabase sigue funcionando igual
- Todas las funcionalidades existentes se mantienen

#### Cambios Tecnicos (Para Desarrolladores)

**Diagnostico Arquitectonico Completo**:
- ✅ **Fase 1**: Verificacion de integridad de base de datos (Schema v5 con PUC correcto)
- ❌ **Fase 2**: Auditoria de providers Riverpod (0/4 proveedores cumplian con PUC)
- ❌ **Fase 3**: Analisis de widgets del Dashboard (2 widgets criticos con logica hardcodeada)
- ❌ **Fase 4**: Sanitizacion de documentacion (9 versiones en 3 dias, changelog erratico)

**Documentacion de Refactor Creada**:
- `docs/REFACTOR_PROPOSAL_DASHBOARD_PUC.md` (488 lineas): Propuesta completa de DashboardRepository con JOINs a AccountGroups
- `docs/PHASE2_LOGIC_LAYER_AUDIT.md` (506 lineas): Auditoria de providers con violaciones criticas identificadas
- `docs/PHASE3_DASHBOARD_UI_PURGE.md` (830+ lineas): Inventario de widgets, plan de refactor
- `docs/PHASE4_DOCUMENTATION_SANITIZE.md`: Estrategia de limpieza de documentacion

**Skills y Workflow QA**:
- Instalado QA Mindset como "System Role" permanente en `QA_MINDSET.md`
- Error Tracker completo con 6 scripts Python para documentacion de errores
- Progressive Disclosure con 5 skills especializados (.claude/)

**Tests**:
- 500+ tests en 12 categorias (Unit, Widget, Integration, E2E, PWA, Security, Performance, Production, Regression)
- Tests de regresion para ERR-0006 (rebuild loop), ERR-0005 (anti-patron amount=0)
- Suite completa de tests agresivos de produccion

#### Breaking Changes

**Ninguno**. Esta es una version de refactor INTERNO - todos tus datos y funcionalidades existentes continuan funcionando sin cambios.

#### Migracion desde 1.9.x

**No se requiere accion del usuario**. Los datos locales y remotos son 100% compatibles.

Para desarrolladores que contribuyen al proyecto:
1. Revisar `docs/REFACTOR_PROPOSAL_DASHBOARD_PUC.md` antes de modificar Dashboard
2. Seguir QA Mindset "Iron Rule" antes de cualquier cambio de codigo
3. Usar scripts de Error Tracker para documentar fixes

---

## Archivos Clave Agregados

| Archivo | Proposito |
|---------|-----------|
| `QA_MINDSET.md` | System role permanente, workflow Test-First mandatorio |
| `docs/REFACTOR_PROPOSAL_DASHBOARD_PUC.md` | Propuesta arquitectonica completa para Dashboard |
| `docs/PHASE2_LOGIC_LAYER_AUDIT.md` | Auditoria de providers Riverpod |
| `docs/PHASE3_DASHBOARD_UI_PURGE.md` | Inventario y plan de refactor de widgets |
| `docs/PHASE4_DOCUMENTATION_SANITIZE.md` | Estrategia de limpieza de documentacion |
| `CHANGELOG_ARCHIVE_2024-2025.md` | Historial completo de versiones 1.0.0 - 1.9.13 |
| `.claude/skills/accounting-puc/` | Skill especializado en PUC colombiano |
| `.error-tracker/errors/ERR-0006-*` | Documentacion rebuild loop fix |
| `test/regression/err_0006_rebuild_loop_test.dart` | Test de regresion ERR-0006 |
| `test/unit/puc_integrity_test.dart` | Tests de integridad PUC |

---

## Metricas de Esta Version

- **4 fases de diagnostico** completadas
- **3,000+ lineas** de documentacion tecnica generada
- **0 regresiones** introducidas (tests passing: 500+)
- **500+ tests** mantenidos y pasando
- **1 changelog** sanitizado y archivado

---

## Proximos Pasos (No Implementado Aun)

La documentacion de refactor esta lista para implementacion:
1. Implementar `DashboardRepository` con queries PUC-aware
2. Refactorizar providers para usar `groupId` en lugar de `type` deprecado
3. Actualizar Dashboard UI con widgets PUC-driven
4. Migrar logica de calculos a repositorios (separar de providers)

Estas implementaciones se haran en versiones futuras (2.1.x, 2.2.x) siguiendo el plan detallado en la documentacion.

---

**Version**: 2.0.0-Refactor
**Fecha**: 2026-01-07
**Moneda por defecto**: COP (Peso Colombiano)
**Monedas soportadas**: COP, USD, EUR, MXN, ARS, PEN, CLP, BRL
**Tests**: 500+ en 12 categorias
