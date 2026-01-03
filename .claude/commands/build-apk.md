---
name: build-apk
description: Construye APK de release y lo copia a Descargas
---

# Build APK

Ejecuta los siguientes pasos para construir el APK de release:

1. Ejecutar tests primero para verificar que todo funciona:
```bash
flutter test
```

2. Analizar codigo para detectar problemas:
```bash
flutter analyze
```

3. Construir APK de release:
```bash
flutter build apk --release
```

4. Copiar APK a carpeta de Descargas con nombre versionado:
```bash
cp build/app/outputs/flutter-apk/app-release.apk ~/Descargas/finanzas-familiares-v$(date +%Y%m%d).apk
```

5. Mostrar ubicacion y tamano del APK generado.
