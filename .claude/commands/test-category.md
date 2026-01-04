# /test-category [category]

Ejecuta tests de una categoria especifica.

## Categorias Disponibles

| Categoria | Path | Descripcion |
|-----------|------|-------------|
| unit | test/unit/ | Logica de negocio |
| widget | test/widget/ | Componentes UI |
| integration | test/integration/ | Flujos completos |
| e2e | test/e2e/ | End-to-end |
| pwa | test/pwa/ | Offline-first |
| supabase | test/supabase/ | Auth y seguridad |
| performance | test/performance/ | Rendimiento |
| android | test/android/ | Compatibilidad |
| production | test/production/ | Robustez |

## Uso

```bash
# Ejecutar categoria especifica
flutter test test/<category>/

# Ejemplos
flutter test test/unit/
flutter test test/pwa/
flutter test test/supabase/
```

## Flags Utiles

```bash
# Verbose output
flutter test test/<category>/ --reporter expanded

# Solo tests que matchean patron
flutter test test/<category>/ --name "patron"

# Paralelo (mas rapido)
flutter test test/<category>/ --concurrency=4
```
