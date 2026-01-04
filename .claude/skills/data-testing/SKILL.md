# Data Testing Skill

Generación e importación de datos de prueba para desarrollo y testing.

## Escenarios Disponibles

### 1. Testing In-App (Flutter)
Generador integrado en la app para crear datos de prueba directamente.

**Ubicación**: `Configuración > Datos de Prueba`

**Features**:
- ✅ Genera 10-200 transacciones fake
- ✅ Crea cuenta de prueba automáticamente
- ✅ Datos realistas colombianos (COP)
- ✅ Sincronización automática a Supabase
- ✅ Patrones: Exito, Rappi, Uber, Netflix, etc.

**Uso**:
1. Abrir app → Configuración → Datos de Prueba
2. Configurar cantidad y rango de días
3. Presionar "Generar Datos"
4. Esperar sincronización (batches cada 10 txs)

**Código**: `lib/features/settings/presentation/screens/import_test_data_screen.dart`

### 2. Testing RPA (Python CLI)
Herramientas CLI para generar/importar datos desde archivos externos.

**Ubicación**: `rpa/main.py`

**Features**:
- ✅ Genera datos en JSON/CSV
- ✅ Importa desde bancos (CSV)
- ✅ Patrones colombianos avanzados
- ✅ Preview y validación
- ✅ Export a formato Flutter

**Uso**:
```bash
cd rpa
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Generar 100 transacciones
python main.py generate --count 100 --days 30

# Preview
python main.py preview output/transactions.json

# Importar CSV de banco
python main.py import-csv bancolombia.csv --format bancolombia
```

**Código**: `rpa/generators/fake_transactions.py`

## Comandos Claude

| Comando | Descripción |
|---------|-------------|
| `/generate-test-data` | Generar datos de prueba (in-app o RPA) |
| `/import-bank-data` | Importar datos de banco vía RPA |
| `/cleanup-test-data` | Limpiar datos de prueba de Supabase |

## Cuando Usar Cada Escenario

### In-App (Flutter)
✅ Testing rápido durante desarrollo
✅ Probar sincronización Supabase
✅ Validar UI con datos reales
✅ Tests E2E en dispositivo

### RPA (Python)
✅ Generar datasets grandes (1000+ txs)
✅ Importar datos reales de bancos
✅ Testing offline (sin Supabase)
✅ CI/CD pipelines

## Patrones de Datos

Ambos escenarios comparten patrones colombianos:

### Ingresos (15%)
- Salario mensual: 2.5M - 8M COP
- Bonificaciones: 500K - 2M COP
- Freelance: 200K - 3M COP

### Gastos Recurrentes
- Arriendo: 800K - 2M COP
- Servicios (EPM): 80K - 350K COP
- Internet/TV: 60K - 150K COP
- Netflix: 26.9K - 44.9K COP
- Spotify: 16.9K - 26.9K COP

### Gastos Variables
- Mercado (Exito): 50K - 350K COP
- Restaurantes (Rappi): 15K - 80K COP
- Transporte (Uber): 8K - 45K COP
- Gasolina: 50K - 200K COP

## Mejores Prácticas

1. **Siempre crear cuenta de prueba** para no mezclar con datos reales
2. **Usar sync manual** después de generar datos masivos
3. **Limpiar datos antiguos** periódicamente
4. **Validar en Supabase** que los datos llegaron correctamente
5. **Documentar casos de uso** específicos de cada patrón

## Troubleshooting

### Datos no sincronizados
Ver `docs/SYNC_DIAGNOSIS.md` para diagnóstico completo.

**Fix rápido**:
- Verificar conectividad
- Forzar sync manual en Configuración
- Verificar que la cuenta existe en Supabase primero

### Error de foreign key
**Causa**: Transacciones se intentan sincronizar antes que la cuenta.

**Fix**: Aplicado en v1.9.3+ (await sync de cuenta primero)

### Datos duplicados
**Causa**: Generar múltiples veces sin limpiar.

**Fix**: Usar `/cleanup-test-data` o eliminar manualmente en Supabase

## Referencias

- [In-App Generator](../../../lib/features/settings/presentation/screens/import_test_data_screen.dart)
- [RPA Tools](../../../rpa/README.md)
- [Sync Diagnosis](../../../docs/SYNC_DIAGNOSIS.md)
- [Sync Testing Guide](../../../docs/SYNC_TESTING_GUIDE.md)

---

**Última actualización**: 2026-01-04
**Escenarios**: 2 (In-App + RPA)
**Patrones**: Colombia (COP)
