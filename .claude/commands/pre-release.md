# /pre-release - Validacion Completa Pre-Produccion

Ejecuta validacion completa antes de release:

## Pasos Automatizados

1. **Analisis estatico**
   ```bash
   flutter analyze
   ```

2. **Tests unitarios**
   ```bash
   flutter test test/unit/
   ```

3. **Tests de widgets**
   ```bash
   flutter test test/widget/
   ```

4. **Tests de produccion agresivos**
   ```bash
   flutter test test/production/
   ```

5. **Build de verificacion**
   ```bash
   flutter build apk --release
   ```

## Criterios de Exito
- 0 errores de analisis
- 100% tests pasando
- Build exitoso sin warnings criticos

## Uso
```
/pre-release
```

Ejecuta todos los pasos y reporta cualquier fallo antes de continuar.
