# RPA Testing Tools - Finanzas Familiares

Herramientas ligeras para generar e importar datos de prueba en la app.

## Instalacion

```bash
cd rpa
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o: venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

## Comandos Disponibles

| Comando | Descripcion |
|---------|-------------|
| `generate` | Crear transacciones fake con patrones colombianos |
| `import-csv` | Importar archivo CSV de banco |
| `import-json` | Importar archivo JSON |
| `preview` | Ver archivo generado |
| `export` | Exportar a formato Flutter/CSV |
| `info` | Ver archivos disponibles |

## Uso Rapido

### Generar transacciones de prueba

```bash
# Generar 100 transacciones de los ultimos 30 dias
python main.py generate --count 100 --days 30

# Generar con patron especifico (salario mensual)
python main.py generate --count 50 --pattern salary

# Ver resultado
python main.py preview output/transactions.json
```

### Importar datos externos

```bash
# Importar CSV de Nequi/Davivienda
python main.py import-csv bancolombia_export.csv --format bancolombia

# Importar JSON custom
python main.py import-json my_data.json
```

### Exportar para Flutter

```bash
# Exportar a formato compatible con app
python main.py export output/transactions.json --format flutter
```

## Patrones de Generacion

El generador incluye patrones realistas para Colombia:

- **Ingresos**: Salario, bonificaciones, freelance
- **Gastos fijos**: Arriendo, servicios, internet, celular
- **Mercado**: Exito, Carulla, D1, Ara, Olimpica
- **Transporte**: Uber, DiDi, gasolina, TransMilenio
- **Restaurantes**: Rappi, iFood, restaurantes locales
- **Suscripciones**: Netflix, Spotify, HBO Max

## Estructura de Archivos

```
rpa/
├── main.py              # CLI principal
├── requirements.txt     # Dependencias (~15 MB)
├── generators/
│   └── fake_transactions.py  # Generador con patrones CO
├── importers/
│   ├── csv_importer.py       # Importador CSV
│   └── json_importer.py      # Importador JSON
├── tests/
│   └── test_generators.py    # Tests unitarios
└── output/                   # Archivos generados
```

## Dependencias

Solo 7 dependencias ligeras:

- `faker` - Generacion de datos falsos
- `click` - CLI framework
- `pandas` - Procesamiento de datos
- `rich` - Output bonito en terminal
- `python-dateutil` - Manejo de fechas
- `pytest` - Testing
- `pyyaml` - Configuracion

## Diferencia con rpa-bank-scrapers

| Caracteristica | bank-scrapers | testing-tools |
|----------------|---------------|---------------|
| Playwright | Si | No |
| Scrapers banco | Nequi, Davivienda | No |
| Email IMAP | Si | No |
| Generador fake | No | Si |
| Importar CSV | No | Si |
| Dependencias | ~200+ MB | ~15 MB |
| Uso | Produccion | Dev/Testing |

## Licencia

MIT - Uso interno para desarrollo y testing.
