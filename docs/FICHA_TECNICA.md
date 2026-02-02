# Ficha Técnica - Platica (Finanzas Familiares AS)

## Información General

| Campo | Valor |
|-------|-------|
| **Nombre Comercial** | Platica |
| **Nombre Técnico** | Finanzas Familiares AS |
| **Package ID** | `app.finanzasfamiliares` |
| **Versión Actual** | 1.20.0+41 |
| **Licencia** | Propietaria (uso personal) |
| **Categoría** | Finanzas Personales |
| **Idioma** | Español (Colombia) |

---

## Contacto y Enlaces

### Desarrollador
| Campo | Valor |
|-------|-------|
| **Desarrollador** | Álvaro Ángel Molina |
| **Cuenta GitHub** | [@alvaretto](https://github.com/alvaretto) |
| **Email GitHub (oficial)** | alvaroangelm@gmail.com |
| **Email GitHub (commits)** | alvaretto@users.noreply.github.com |

### Repositorio
| Campo | Valor |
|-------|-------|
| **URL Repositorio** | https://github.com/alvaretto/finanzasfamilia |
| **Visibilidad** | Privado |
| **Branch Principal** | `main` |

### Distribución
| Campo | Valor |
|-------|-------|
| **Play Store URL** | https://play.google.com/store/apps/details?id=app.finanzasfamiliares |
| **Email Play Store** | condenada.marucha@gmail.com |
| **Estado Play Store** | Prueba Cerrada (pendiente producción) |
| **Testers Requeridos** | 12 (actualmente 3/12) |

---

## Especificaciones Técnicas

### Plataforma
| Campo | Valor |
|-------|-------|
| **Framework** | Flutter 3.35.7 (stable) |
| **Lenguaje** | Dart 3.9.2 |
| **Plataforma Objetivo** | Android |
| **Compile SDK** | 36 |
| **Min SDK** | 21 (Android 5.0 Lollipop) |
| **Target SDK** | 34 (Android 14) |

### Arquitectura
| Campo | Valor |
|-------|-------|
| **Patrón** | Clean Architecture |
| **Estado** | Riverpod 2.6.1 |
| **Base de Datos Local** | Drift 2.28.2 (SQLite) |
| **Sincronización** | PowerSync 1.17.0 |
| **Backend** | Supabase 2.12.0 |
| **Autenticación** | Google OAuth + Email/Password |

### Métricas de Código
| Métrica | Valor |
|--------|-------|
| **Archivos Fuente** | 264 |
| **Líneas de Código** | ~79,000 |
| **Tests Unitarios** | 1,137 |
| **Cobertura Funcional** | Alta |
| **Análisis Estático** | 0 warnings, 0 errors |

---

## Dependencias Principales

### Core
| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| flutter_riverpod | 2.6.1 | Gestión de estado |
| drift | 2.28.2 | ORM SQLite |
| powersync | 1.17.0 | Sincronización (offline después de sync inicial) |
| supabase_flutter | 2.12.0 | Backend-as-a-Service |
| freezed | 2.5.8 | Inmutabilidad de modelos |

### Firebase
| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| firebase_core | 3.15.2 | Core Firebase |
| firebase_crashlytics | 4.3.10 | Reporte de errores |
| firebase_analytics | 11.6.0 | Analíticas |

### Funcionalidades
| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| fl_chart | 0.69.2 | Gráficos financieros |
| google_mlkit_text_recognition | 0.14.0 | OCR para facturas |
| image_picker | 1.2.0 | Captura de imágenes |
| excel | 4.0.6 | Exportación Excel |
| pdf | 3.11.3 | Generación de reportes PDF |
| home_widget | 0.9.0 | Widget de escritorio Android |

---

## Funcionalidades Principales

### Motor Contable
- Contabilidad de partida doble automática
- Balance general y estado de resultados
- Validación de fondos insuficientes
- Reversión transaccional atómica

### Gestión Financiera
- Cuentas (activos, pasivos, patrimonio)
- Categorías jerárquicas (hasta 4 niveles)
- Presupuestos mensuales con alertas
- Metas de ahorro con seguimiento

### Transacciones
- Gastos con nivel de satisfacción
- Ingresos
- Transferencias entre cuentas
- Pagos de pasivos (tarjetas de crédito)
- Transacciones recurrentes

### Inteligencia Artificial
- Asistente "Fina" con Claude Sonnet
- Escaneo de facturas (OCR + IA)
- Lectura de notificaciones bancarias

### Sincronización
- Arquitectura offline-first con PowerSync
- **Requiere internet** para login inicial y primera sincronización
- Operación offline disponible después de sincronización inicial
- Backup automático en Google Drive (Android)
- Recuperación de datos post-reinstalación
- Funcionalidades que **siempre requieren internet**: Asistente Fina, sync entre dispositivos

---

## Artefactos de Build

### Release Actual (v1.20.0+41)
| Artefacto | Tamaño | Uso |
|-----------|--------|-----|
| APK | 101 MB | Instalación directa |
| AAB | 67 MB | Play Store |

### Firmado
| Campo | Valor |
|-------|-------|
| **Keystore** | upload-keystore.jks |
| **Key Alias** | upload |
| **Algoritmo** | SHA-256 |

---

## Infraestructura Backend

### Supabase
| Campo | Valor |
|-------|-------|
| **Project ID** | arawzleeiohoyhonisvo |
| **Región** | South America (São Paulo) |
| **Plan** | Free Tier |
| **Keep-Alive** | GitHub Action cada 3 días |

### PowerSync
| Campo | Valor |
|-------|-------|
| **Instance URL** | https://6961035c30605f245f00db3c.powersync.journeyapps.com |
| **Tablas Sincronizadas** | 20 |
| **Estrategia** | Bidireccional |

---

## Historial de Versiones Recientes

| Versión | Fecha | Cambios Principales |
|---------|-------|---------------------|
| 1.20.0+41 | 2026-02-02 | Campo satisfacción en gastos + Ficha técnica |
| 1.19.0+40 | 2026-01-31 | Sync sequence + Keep-alive |
| 1.15.0+36 | 2026-01-14 | Fix accounts type sync |
| 1.14.0+35 | 2026-01-14 | Native Google Sign-In |
| 1.12.0+27 | 2026-01-13 | PowerSync configurado |

---

## Requisitos del Sistema

### Dispositivo
- Android 5.0 (Lollipop) o superior
- ~150 MB espacio disponible

### Conectividad
- **Obligatorio**: Internet para login inicial y primera sincronización
- **Opcional**: Internet para operación posterior (modo offline disponible)
- **Siempre online**: Asistente IA "Fina", sincronización multi-dispositivo

### Permisos
- Cámara (escaneo de facturas)
- Almacenamiento (adjuntos)
- Internet (sincronización)
- Notificaciones (alertas de presupuesto)
- Lectura de notificaciones (opcional, bancos)

---

## Documentación Relacionada

| Documento | Ubicación |
|-----------|-----------|
| Instrucciones de desarrollo | `CLAUDE.md` |
| Guía del modo personal | `docs/GUIA_MODO_PERSONAL_nuevo.md` |
| Estrategia de testing | `docs/TESTING_STRATEGY.md` |
| Keep-alive Supabase | `docs/SUPABASE_KEEP_ALIVE.md` |
| Changelog completo | `docs/CHANGELOG.md` |

---

*Última actualización: 2026-02-02*
