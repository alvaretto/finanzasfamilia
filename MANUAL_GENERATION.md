# MANUAL_GENERATION.md - Comandos de Generación Manual

Este archivo lista los comandos que **debes ejecutar manualmente** cuando Claude te lo indique.
Claude NO ejecutará estos comandos automáticamente para ahorrar tokens.

---

## Comandos Frecuentes

### 1. Obtener Dependencias
Ejecutar después de modificar `pubspec.yaml`:

```bash
flutter pub get
```

### 2. Code Generation (build_runner)
Ejecutar después de crear/modificar archivos con:

- `@freezed` (modelos)
- `@riverpod` (providers)
- `@DriftDatabase` / `@DataClassName` (tablas Drift)

```bash
# Generación única
dart run build_runner build --delete-conflicting-outputs

# Watch mode (desarrollo continuo)
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Generar Schema de PowerSync
Después de modificar tablas de Drift:
```bash
# Si tienes script personalizado
dart run tool/generate_powersync_schema.dart
```

---

## Nuevas Dependencias (Fase 1.5+)

### Agregar paquetes de Export/Import y Conectividad
```bash
# Paquetes de exportación
flutter pub add excel
flutter pub add csv
flutter pub add pdf

# Almacenamiento y conectividad
flutter pub add path_provider
flutter pub add connectivity_plus

# Después de agregar, ejecutar:
flutter pub get
```

### Paquetes Opcionales
```bash
# Para compartir archivos exportados
flutter pub add share_plus

# Para seleccionar archivos de importación
flutter pub add file_picker
```

---

## Comandos por Escenario

### A. Nuevo Modelo Freezed
1. Claude crea: `lib/domain/entities/mi_modelo.dart`
2. **TÚ ejecutas:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Se genera: `lib/domain/entities/mi_modelo.freezed.dart`

### B. Nuevo Provider Riverpod
1. Claude crea: `lib/application/providers/mi_provider.dart`
2. **TÚ ejecutas:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Se genera: `lib/application/providers/mi_provider.g.dart`

### C. Nueva Tabla Drift

1. Claude crea: `lib/data/local/tables/mi_tabla.dart`
2. Claude modifica: `lib/data/local/database.dart`
3. **TÚ ejecutas:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Se genera: `lib/data/local/database.g.dart`

### D. Actualizar pubspec.yaml
1. Claude modifica: `pubspec.yaml`
2. **TÚ ejecutas:**
   ```bash
   flutter pub get
   ```

### E. Agregar Nuevas Dependencias (Fase 1.5)
1. Claude te indica qué paquetes necesitas
2. **TÚ ejecutas:**
   ```bash
   flutter pub add <paquete1> <paquete2> ...
   flutter pub get
   ```

---

## Comandos de Testing

### Ejecutar todos los tests
```bash
flutter test
```

### Ejecutar test específico
```bash
flutter test test/unit/mi_test.dart
```

### Ejecutar tests con cobertura
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Comandos de Análisis

### Análisis estático
```bash
flutter analyze
```

### Formateo de código
```bash
dart format lib/ test/
```

---

## Comandos de Export/Import (Fase 4)

### Ubicación de archivos exportados
```bash
# Ver directorio de documentos de la app
adb shell "run-as com.example.finanzas_familiares ls /data/data/com.example.finanzas_familiares/app_flutter"

# O en iOS Simulator
open ~/Library/Developer/CoreSimulator/Devices/
```

### Copiar archivo exportado del dispositivo
```bash
# Android
adb pull /data/data/com.example.finanzas_familiares/app_flutter/export.xlsx ./

# iOS (simulador) - usar el path específico del simulador
```

---

## Troubleshooting

### Error: "Could not find a file named..."
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Error: "Conflicting outputs"
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Cache corrupto
```bash
flutter clean
rm -rf .dart_tool/
flutter pub get
```

### Error: Package not found
```bash
flutter pub cache repair
flutter pub get
```

### Error en tests de Drift (SQLite)
```bash
# Asegúrate de tener sqlite3 instalado
# macOS: brew install sqlite3
# Linux: sudo apt install libsqlite3-dev
```

---

## Flujo Típico de Desarrollo

```
┌─────────────────────────────────────────────────┐
│ 1. Claude escribe código nuevo                  │
├─────────────────────────────────────────────────┤
│ 2. Claude te indica: "Ejecuta build_runner"     │
├─────────────────────────────────────────────────┤
│ 3. TÚ ejecutas el comando                       │
├─────────────────────────────────────────────────┤
│ 4. TÚ confirmas: "Listo" o "Error: ..."         │
├─────────────────────────────────────────────────┤
│ 5. Claude continúa con el siguiente paso        │
└─────────────────────────────────────────────────┘
```

---

## Resumen de Paquetes Requeridos

| Paquete | Uso | Comando |
|---------|-----|---------|
| `excel` | Export/Import Excel | `flutter pub add excel` |
| `csv` | Export/Import CSV | `flutter pub add csv` |
| `pdf` | Export PDF | `flutter pub add pdf` |
| `path_provider` | Rutas de almacenamiento | `flutter pub add path_provider` |
| `connectivity_plus` | Detección de red | `flutter pub add connectivity_plus` |
| `share_plus` | Compartir archivos | `flutter pub add share_plus` |
| `file_picker` | Seleccionar archivos | `flutter pub add file_picker` |

---

**Tip:** Mantén una terminal abierta con `dart run build_runner watch` para generación automática durante desarrollo intensivo.
