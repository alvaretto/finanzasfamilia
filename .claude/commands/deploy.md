# /deploy - Build y Deployment

Construye y prepara para deployment:

## Argumentos
- `--version VERSION`: Version del release (ej: v1.6.0)
- `--platform PLATFORM`: android | linux | all (default: android)

## Pasos

### Android
```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ~/Descargas/finanzas-familiares-$VERSION.apk
```

### Linux
```bash
flutter build linux --release
# Output en build/linux/x64/release/bundle/
```

## Post-Deploy
- Actualizar CHANGELOG.md
- Crear tag de git
- Commit con mensaje de release

## Ejemplo
```
/deploy --version v1.6.0 --platform android
```
