# RPA Bank Scrapers - Finanzas Familiares

Sistema de automatización (RPA) para extraer transacciones bancarias de entidades colombianas.

## 🏦 Bancos Soportados

| Banco | Estado | Notas |
|-------|--------|-------|
| Nequi | ✅ Implementado | Requiere OTP manual |
| Davivienda | ✅ Implementado | Requiere OTP manual |
| Bancolombia | 🔜 Próximamente | - |
| DaviPlata | 🔜 Próximamente | - |

## 📋 Requisitos

- Python 3.10+
- Playwright
- Cuenta de correo para notificaciones (Gmail/Outlook)

## 🚀 Instalación

```bash
# Desde la raíz del proyecto
cd rpa

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o en Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Instalar navegadores de Playwright
playwright install chromium
```

## ⚙️ Configuración

1. Copiar el archivo de ejemplo:
```bash
cp .env.example .env
```

2. Editar `.env` con tus credenciales:
```env
# Nequi
NEQUI_PHONE=3001234567
NEQUI_PASSWORD=tu_password

# Davivienda
DAVIVIENDA_USER=tu_usuario
DAVIVIENDA_PASSWORD=tu_password

# Email (para notificaciones de compras)
EMAIL_PROVIDER=gmail  # o outlook
EMAIL_ADDRESS=tu@email.com
EMAIL_APP_PASSWORD=tu_app_password

# Supabase (opcional, para sync directo)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_KEY=tu_anon_key
```

## 📖 Uso

### Ejecución Manual

```bash
# Extraer transacciones de Nequi
python main.py --bank nequi --days 30

# Extraer transacciones de Davivienda
python main.py --bank davivienda --days 30

# Extraer notificaciones de email
python main.py --email --days 7

# Todos los bancos
python main.py --all --days 30
```

### Modo Interactivo (para OTP)

```bash
# Abre el navegador visible para ingresar OTP manualmente
python main.py --bank nequi --interactive
```

### Salida

Los datos se exportan a `output/` en formato JSON:

```json
{
  "bank": "nequi",
  "extracted_at": "2026-01-04T10:30:00",
  "transactions": [
    {
      "id": "TXN123456",
      "date": "2026-01-03",
      "description": "Pago PSE - Netflix",
      "amount": -45900,
      "type": "expense",
      "category_hint": "entretenimiento",
      "balance_after": 1250000
    }
  ]
}
```

## 🔄 Automatización con Cron

```bash
# Configurar cron job (ejecuta diariamente a las 6 AM)
chmod +x cron_setup.sh
./cron_setup.sh
```

El script configura:
- Extracción diaria de transacciones
- Rotación de logs
- Notificación por email en caso de error

## 🔐 Seguridad

⚠️ **IMPORTANTE:**

1. **Nunca** commits el archivo `.env` (ya está en `.gitignore`)
2. Las credenciales se almacenan solo localmente
3. El estado de sesión (`storage_state.json`) se guarda encriptado
4. No compartir los archivos de `output/` con datos reales

## 🧪 Testing

```bash
# Ejecutar tests
pytest tests/ -v

# Test de un scraper específico
pytest tests/test_nequi.py -v
```

## 📁 Estructura

```
rpa/
├── config.py              # Configuración y variables de entorno
├── main.py                # Script principal CLI
├── requirements.txt       # Dependencias Python
├── cron_setup.sh          # Setup de automatización
├── scrapers/
│   ├── __init__.py
│   ├── base_scraper.py    # Clase base abstracta
│   ├── nequi_scraper.py   # Scraper de Nequi
│   ├── davivienda_scraper.py  # Scraper de Davivienda
│   └── email_scraper.py   # Scraper de emails
├── parsers/
│   ├── __init__.py
│   └── transaction_parser.py  # Parser y normalizador
├── output/                # Archivos JSON exportados
│   └── .gitkeep
├── storage/               # Estados de sesión (encriptados)
│   └── .gitkeep
├── logs/                  # Logs de ejecución
│   └── .gitkeep
└── tests/
    └── test_scrapers.py
```

## 🔧 Solución de Problemas

### El OTP no llega
- Verifica que el número de teléfono sea correcto
- Espera al menos 60 segundos entre intentos
- Revisa la bandeja de spam del correo

### Error de timeout
- Aumenta el timeout en `config.py`
- Verifica tu conexión a internet
- Los bancos pueden tener mantenimiento

### El scraper no encuentra elementos
- Los bancos actualizan su UI frecuentemente
- Abre un issue en GitHub con el error
- Usa `--debug` para ver screenshots

## 📝 Licencia

MIT - Uso personal únicamente. No usar para acceder a cuentas de terceros.
