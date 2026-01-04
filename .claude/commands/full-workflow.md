---
name: full-workflow
description: Ejecuta el workflow completo de desarrollo (tests, build, deploy)
---

# Full Workflow

Workflow automatizado completo para desarrollo y deployment.

## Pasos del Workflow

### 1. Verificacion Pre-Build
```bash
# Verificar estado de git
git status --short

# Verificar dependencias
flutter pub get
```

### 2. Generacion de Codigo
```bash
# Regenerar codigo freezed/drift/riverpod
dart run build_runner build -d
```

### 3. Analisis Estatico
```bash
# Verificar errores de compilacion
flutter analyze
```

### 4. Ejecutar Tests (300+)
```bash
# Tests por categoria
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/ai_chat/
flutter test test/security/
flutter test test/performance/
flutter test test/pwa/
flutter test test/android/
flutter test test/production/
```

### 5. Build APK Release
```bash
flutter build apk --release
```

### 6. Copiar APK a Descargas
```bash
cp build/app/outputs/flutter-apk/app-release.apk ~/Descargas/finanzas-familiares-$(date +%Y%m%d).apk
```

### 7. Git Commit y Push
```bash
# Solo si todos los tests pasan
git add -A
git commit -m "chore: workflow update $(date +%Y-%m-%d)"
git push origin main
```

### 8. Instalar en Emulador (opcional)
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Verificacion Final

Reportar:
- Numero de tests pasados/fallidos
- Tamano del APK
- Commit hash generado
- Estado del emulador

## Notas

- El workflow se detiene si algun paso falla
- Los tests E2E requieren Supabase inicializado
- El push se hace solo si todos los tests pasan
