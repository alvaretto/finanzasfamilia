# /setup - Configurar Entorno de Desarrollo

Ejecuta el script de configuración de infraestructura para Manjaro Linux.

## Acciones

1. Ejecutar script de setup:

```bash
./scripts/setup_manjaro_env.sh
```

## Qué configura

- **FVM**: Instala y configura Flutter Version Manager
- **Flutter**: Descarga la versión especificada (3.27.2)
- **KVM**: Verifica que esté habilitado para emulación
- **AVD**: Crea el emulador `FinanzasEnv` (Pixel 6, API 34)

## Prerequisitos

- Manjaro Linux con KVM habilitado
- Android SDK instalado (via Android Studio o manual)
- Dart SDK disponible

## Post-Setup

Después de ejecutar, verificar:
```bash
fvm flutter doctor
```
