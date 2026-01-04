# /test-all

Ejecuta la suite completa de tests con reporte detallado.

## Proceso

1. **Pre-check**: Verificar que no hay errores de compilacion
2. **Unit Tests**: Logica de negocio
3. **Widget Tests**: Componentes UI
4. **Integration Tests**: Flujos completos
5. **PWA/Offline Tests**: Comportamiento offline
6. **Supabase Tests**: Auth y seguridad
7. **Performance Tests**: Rendimiento
8. **Android Tests**: Compatibilidad
9. **Production Tests**: Robustez
10. **E2E Tests**: End-to-end

## Comandos

```bash
# Verificar compilacion
flutter analyze

# Ejecutar todos los tests
flutter test --reporter expanded

# Con coverage
flutter test --coverage

# Ver reporte
genhtml coverage/lcov.info -o coverage/html
```

## Output Esperado

- Total tests ejecutados
- Tests pasados/fallidos por categoria
- Tiempo de ejecucion
- Coverage porcentaje

## Criterios de Exito

- 0 tests fallidos en unit/widget/integration
- < 5% tests fallidos en E2E (pueden fallar por timing)
- Coverage > 60%
