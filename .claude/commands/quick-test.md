# /quick-test

Ejecuta tests rapidos para validacion durante desarrollo.

## Scope

Solo ejecuta tests que:
- Son rapidos (< 5 segundos total)
- Validan funcionalidad core
- No requieren setup complejo

## Comando

```bash
flutter test test/unit/ test/widget/ --concurrency=4
```

## Cuando Usar

- Antes de cada commit
- Durante desarrollo activo
- Validacion rapida de cambios

## Tests Incluidos

1. **Unit Tests**: Modelos, validaciones, calculos
2. **Widget Tests**: Renderizado basico, interacciones

## Tests Excluidos

- E2E (lentos)
- Integration (requieren setup)
- Performance (consumen recursos)
- Android compatibility (requieren emulador)

## Tiempo Esperado

< 10 segundos en hardware moderno
