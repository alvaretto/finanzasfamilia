# Changelog

Todos los cambios notables en Finanzas Familiares AS seran documentados en este archivo.

## [1.6.0] - 2026-01-03

### Agregado
- **Google Sign-In Nativo**: Reemplazado OAuth web por google_sign_in nativo
  - Mejor UX: selector de cuenta nativo en lugar de navegador externo
  - ID token integrado con Supabase Auth
- **Deep Links OAuth**: Soporte para io.supabase.finanzasfamiliares://
- **Tests de Produccion v2**: 40+ tests agresivos adicionales:
  - Balances astronomicos (trillones) sin overflow
  - Balances negativos extremos
  - Strings de 10,000 caracteres
  - Unicode, emojis, y caracteres especiales
  - Fechas edge case (1900, 2099, leap year)
  - Stress test: 10,000 transacciones en <5s
  - Filtrado de 10,000 items en <1s
  - Division por cero en todos los calculos financieros
  - Verificacion de inmutabilidad
  - Precision decimal en calculos

### Corregido
- **LocaleDataException**: Inicializado DateFormat en espanol antes de uso
- **Pantalla Movimientos**: Ya no muestra error rojo al abrir

### Documentacion
- Workflow .claude completo con Progressive Disclosure
- 4 skills especializados
- 6 comandos automatizados
- 4 hooks de productividad

## [1.2.0] - 2026-01-03

### Agregado
- **Tests de Produccion Agresivos**: Nueva suite de tests en `test/production/` que verifica:
  - Manejo de valores extremos (balances muy grandes/pequenos)
  - Caracteres especiales y emojis en strings
  - Prevencion de division por cero
  - Seguridad de memoria con listas grandes (10,000+ items)
  - Null safety en todos los modelos
  - Calculos financieros correctos (patrimonio neto, credito disponible)

### Corregido
- **Sync silencioso**: Los providers (accounts, transactions, budgets, goals) ahora fallan silenciosamente en syncs automaticos, evitando mensajes de error molestos al usuario
- **Deteccion de errores de IA**: Mejorada la deteccion de rate limits de Gemini API (429, RESOURCE_EXHAUSTED) vs otros errores
- **Eliminado print en produccion**: Removido print statement de debug en ai_chat_service.dart

### Tests
- 172 tests pasando (unit, widget, integration, production)
- 16 nuevos tests de produccion agregados

## [1.1.0] - 2026-01-03

### Agregado
- **First Account Wizard**: Nuevo wizard para guiar a usuarios nuevos a crear su primera cuenta
- **Templates de cuentas**: 5 templates predefinidos (Efectivo, Cuenta Bancaria, Tarjeta de Credito, Ahorros, Billetera Digital)
- **Nuevos tipos de cuenta**: loan (prestamo), receivable (por cobrar), payable (por pagar)
- **Propiedades isLiability/isAsset**: Para clasificar cuentas como activos o pasivos
- **Taxonomia completa de categorias**: 15 categorias de gasto + 6 de ingreso con subcategorias

### Corregido
- Switch statements actualizados para nuevos AccountTypes
- Tests de modelos actualizados

## [1.0.0] - 2026-01-02

### Lanzamiento inicial
- Gestion de cuentas multiples (banco, efectivo, credito, inversiones)
- Registro de transacciones (ingresos, gastos, transferencias)
- Presupuestos por categoria
- Metas de ahorro
- Reportes y graficos
- Sincronizacion con Supabase (offline-first)
- Asistente financiero con IA (Fina)
- Soporte multiplataforma (Android, Linux Desktop)
