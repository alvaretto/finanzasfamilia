# Hook: Post Build

## Trigger
Despues de ejecutar `flutter build apk` exitosamente

## Acciones

1. **Verificar tamano de APK**
   ```bash
   ls -lh build/app/outputs/flutter-apk/app-release.apk
   ```
   - Advertir si > 100MB

2. **Copiar APK a releases/**
   ```bash
   mkdir -p releases
   cp build/app/outputs/flutter-apk/app-release.apk releases/finanzas-familiares-v$(date +%Y%m%d).apk
   ```

3. **Sugerir siguiente paso**
   - Instalar en emulador: `adb install -r ...`
   - Crear release en GitHub: `gh release create ...`
   - Commit y push

## Notificar

- Tamano final del APK
- Tiempo de build
- Ubicacion del archivo
