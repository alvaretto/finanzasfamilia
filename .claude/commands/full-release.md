# /full-release

Workflow completo para release de produccion.

## Pasos Automatizados

### 1. Pre-validacion
```bash
flutter analyze
flutter test
```

### 2. Build APK
```bash
flutter build apk --release
```

### 3. Verificacion Post-Build
- Tamano de APK < 100MB
- Sin warnings criticos
- Firma correcta

### 4. Instalacion en Emulador
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 5. Git Commit
```bash
git add .
git commit -m "release: v<version>"
git push origin main --force
```

### 6. GitHub Release (opcional)
```bash
gh release create v<version> \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "Finanzas Familiares v<version>" \
  --notes "Release notes..."
```

## Checklist Pre-Release

- [ ] Todos los tests pasan
- [ ] flutter analyze sin errores
- [ ] Version actualizada en pubspec.yaml
- [ ] CHANGELOG.md actualizado
- [ ] APK firmado correctamente
- [ ] Probado en emulador

## Rollback

Si algo falla:
```bash
git revert HEAD
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
