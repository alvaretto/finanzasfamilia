# Hook: Pre Build

## Trigger
Antes de ejecutar `flutter build apk`

## Acciones

1. **Ejecutar tests rapidos**
   ```bash
   flutter test test/unit/ test/widget/
   ```

2. **Verificar analisis**
   ```bash
   flutter analyze
   ```

3. **Verificar version**
   - Revisar que pubspec.yaml tiene version actualizada

4. **Limpiar build anterior**
   ```bash
   flutter clean
   flutter pub get
   ```

## Bloquear Si

- Tests fallan
- Errores de analisis
- Dependencias desactualizadas

## Advertir Si

- Tests E2E no se ejecutaron recientemente
- Coverage < 50%
