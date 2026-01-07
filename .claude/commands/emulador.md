---
name: emulador
description: Build APK, copiar a Descargas, instalar en emulador y mostrarlo
---

# Emulador - Build & Deploy

Workflow completo automatizado para construir, instalar y mostrar la app en el emulador.

## Ejecución Automatizada

El script `deploy_to_emulator.sh` ejecuta todos los pasos automáticamente:

```bash
./deploy_to_emulator.sh
```

## Qué hace el script

1. **Build APK**: Construye el APK de release con `flutter build apk --release`

2. **Copiar a Descargas**: Copia el APK a `~/Descargas/` con nombre versionado:
   - Formato: `finanzas-familiares-v{version}-{timestamp}.apk`
   - Ejemplo: `finanzas-familiares-v1.9.3-20260106-235959.apk`

3. **Verificar/Iniciar Emulador**:
   - Si el emulador ya está corriendo, lo usa
   - Si no, inicia `Pixel_6_API_34`
   - Espera hasta 120 segundos a que esté listo

4. **Instalar APK**: Instala el APK en el emulador usando `adb install -r` (mantiene datos)

5. **Lanzar App**: Inicia la aplicación automáticamente

6. **Resumen**: Muestra información del deployment:
   - Nombre y ubicación del APK
   - Tamaño del archivo
   - Emulador utilizado
   - Comandos útiles para debugging

## Notas

- Si el emulador ya está corriendo, solo instalará y lanzará la app
- El APK se copia a `~/Descargas/` con nombre versionado y timestamp
- Usa `-r` en `adb install` para reinstalar sin desinstalar (mantiene datos)
- El timeout de inicio del emulador es de 60 segundos

## Troubleshooting

### Emulador no inicia
```bash
# Listar emuladores disponibles
/home/bootcamp/android-sdk/emulator/emulator -list-avds

# Verificar que el emulador esté en la lista
```

### ADB no encuentra dispositivos
```bash
# Reiniciar servidor ADB
/home/bootcamp/android-sdk/platform-tools/adb kill-server
/home/bootcamp/android-sdk/platform-tools/adb start-server
```

### App no se instala
```bash
# Desinstalar versión anterior primero
/home/bootcamp/android-sdk/platform-tools/adb uninstall com.spaceotech.finanzas_familiares

# Instalar de nuevo
/home/bootcamp/android-sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-release.apk
```
