# Hook: Post Test Write

## Trigger
Cuando se crea o modifica un archivo en `test/`

## Acciones

1. **Verificar sintaxis**
   ```bash
   dart analyze test/<modified_file>
   ```

2. **Ejecutar test modificado**
   ```bash
   flutter test test/<modified_file>
   ```

3. **Sugerir tests relacionados**
   - Si es test de modelo, sugerir test de repository
   - Si es test de widget, sugerir test de integracion

## Recordatorios

- Agregar `setUpAll(() => SupabaseClientProvider.enableTestMode())`
- Agregar `tearDownAll(() => SupabaseClientProvider.reset())`
- Usar `TestMainScaffold` en lugar de `MainScaffold`
- Verificar que el test es independiente
