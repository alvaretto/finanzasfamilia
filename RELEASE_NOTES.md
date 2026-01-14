# Notas de Lanzamiento - v1.18.0

## Resumen
Esta versión consolida la arquitectura Offline-First con mejoras críticas en la sincronización y la seguridad de datos. Se introduce el "Sync Sequence" estilo Linear para garantizar el orden de operaciones y se habilita el respaldo automático en Android.

## Cambios Principales

### 🔄 Sincronización Robusta (Sync Sequence)
- Implementación de secuencia incremental para transacciones.
- Eliminación de violaciones de integridad referencial (FK) mediante ordenamiento por niveles.
- Soporte para sincronización de 15 tablas críticas incluyendo categorías, cuentas y transacciones.

### 🛡️ Seguridad y Respaldo
- **Android Auto Backup:** Configuración de reglas para respaldar la base de datos local en Google Drive.
- **Upload Queue Monitoring:** Diagnóstico en tiempo real del estado de la cola de subida.
- **Recuperación ante Desastres:** Persistencia de sesión mejorada para sobrevivir a reinstalaciones.

### 🛠️ Correcciones
- Solución al problema de pérdida de datos por incompatibilidad de esquemas (Account Type).
- Fix para el escaneo de facturas (Receipt Scanner).
- Estabilización de tests de sincronización.

## Versión Técnica
- **Build:** 1.18.0+39
- **Flutter:** 3.35.7
- **Database:** Drift 2.28.2 / PowerSync 1.17.0
