# Changelog

## v1.18.0 (2026-01-14)
- **SYNC SEQUENCE - Orden Global de Operaciones (Estilo Linear):**
  - Implementación de sync_sequence incremental.
  - FK violations resueltas.
  - Tablas modificadas: categories, accounts, transactions, etc.
- **ANDROID AUTO BACKUP:**
  - Backup automático en Google Drive configurado.
  - Upload Queue Monitoring implementado.

## v1.17.0 (2026-01-14)
- **FIX CRÍTICO: Accounts Type Sync:**
  - Solución a pérdida de datos por columna `type` faltante.
  - Migración de Supabase y Drift.

## v1.14.0 (2026-01-14)
- **NATIVE GOOGLE SIGN-IN:**
  - Solución definitiva al problema OAuth con `google_sign_in`.

## v1.13.0 (2026-01-14)
- **AGGRESSIVE SYNC TESTS:**
  - Suite de 102 tests para ciclo de vida de sincronización.

## v1.12.4 (2026-01-13)
- **LEVEL-BY-LEVEL CATEGORY SYNC:**
  - Inserción ordenada por niveles para evitar FK violations.

## v1.12.2 (2026-01-13)
- **DETERMINISTIC UUIDS FOR SYNC:**
  - UUIDs consistentes entre instalaciones para evitar duplicados.

## v1.12.1 (2026-01-13)
- **CODE QUALITY CLEANUP:**
  - Eliminación de warnings y limpieza de código.

## v1.12.0 (2026-01-13)
- **POWERSYNC CONFIGURADO:**
  - Conexión exitosa a Supabase y sincronización inicial.

## v1.11.0 (2026-01-13)
- **DISASTER RECOVERY:**
  - Persistencia de sesiones con `flutter_secure_storage`.
  - Recuperación post-reinstalación.
