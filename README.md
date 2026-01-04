# Finanzas Familiares AS

App de finanzas personales y familiares multiplataforma con soporte offline-first, sincronizacion en la nube y asistente IA integrado.

## Caracteristicas Principales

- **Multi-cuenta**: Gestiona efectivo, bancos, tarjetas de credito, inversiones
- **Transacciones**: Registra ingresos, gastos y transferencias con categorias
- **Presupuestos Inteligentes**: Define limites por categoria con alertas
- **Metas de Ahorro**: Seguimiento visual de objetivos financieros
- **Reportes**: Graficos interactivos (barras, pie, lineas)
- **Gestion Familiar**: Comparte finanzas con miembros del hogar
- **Asistente IA (Fina)**: Chat inteligente para consultas financieras
- **Offline-First**: Funciona sin conexion, sincroniza automaticamente
- **Multiplataforma**: Android, Linux Desktop (proximamente iOS, Windows, Web)

## Requisitos del Sistema

### Para Desarrollo
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code
- Git

### Para Uso
- **Android**: 7.0+ (API 24)
- **Linux**: Ubuntu 20.04+ / Manjaro / Fedora

## Instalacion Rapida

```bash
# Clonar repositorio
git clone https://github.com/alvaretto/finanzasfamilia.git
cd finanzasfamilia

# Instalar dependencias
flutter pub get

# Generar codigo (freezed, drift, riverpod)
dart run build_runner build -d

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Ejecutar
flutter run
```

## Configuracion

Crea un archivo `.env` en la raiz del proyecto:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
GEMINI_API_KEY=tu-gemini-api-key
```

## Build para Produccion

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# Linux Desktop
flutter build linux --release
```

## Arquitectura

```
lib/
├── core/                  # Infraestructura base
│   ├── database/          # Drift tables y DAOs
│   ├── network/           # Supabase client, sync service
│   ├── router/            # go_router navigation
│   ├── theme/             # Design system
│   └── utils/             # Helpers, extensions
├── features/              # Modulos por funcionalidad
│   ├── auth/              # Login, registro, Google Sign-In
│   ├── accounts/          # Cuentas bancarias y efectivo
│   ├── transactions/      # Ingresos, gastos, transferencias
│   ├── budgets/           # Presupuestos por categoria
│   ├── goals/             # Metas de ahorro
│   ├── reports/           # Graficos y analytics
│   ├── ai_chat/           # Asistente IA (Fina)
│   ├── family/            # Gestion familiar
│   ├── recurring/         # Transacciones recurrentes
│   └── settings/          # Configuracion
├── shared/                # Widgets y providers compartidos
└── main.dart              # Entry point
```

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| Framework | Flutter 3.24+ |
| State Management | Riverpod 2.6 |
| Database Local | Drift + SQLite |
| Backend | Supabase |
| Navegacion | go_router |
| Modelos | freezed |
| Charts | fl_chart |
| AI | Google Gemini |
| Auth | Google Sign-In nativo |

## Testing

```bash
# Todos los tests
flutter test

# Tests por categoria
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/ai_chat/
flutter test test/security/
flutter test test/performance/
flutter test test/pwa/
flutter test test/android/

# Con coverage
flutter test --coverage
```

### Categorias de Tests (300+)

| Categoria | Descripcion |
|-----------|-------------|
| Unit | Logica de negocio, modelos |
| Widget | Componentes UI |
| Integration | Flujos completos |
| AI Chat | Servicio Gemini, mensajes |
| Security | Validacion, RLS, API |
| Performance | Tiempos, memoria |
| PWA | Offline-first, sync |
| Android | Compatibilidad, temas |
| Production | Casos extremos, stress |

## Seguridad

- **Offline-first**: Datos almacenados localmente con SQLite
- **Encriptacion**: flutter_secure_storage para credenciales
- **Row Level Security**: Aislamiento de datos por usuario en Supabase
- **JWT Auth**: Autenticacion segura con refresh tokens
- **Google Sign-In**: Login nativo sin navegador externo
- **Validacion de entrada**: SQL injection, XSS prevenidos

## Comandos Utiles

```bash
# Watch mode para generacion de codigo
dart run build_runner watch

# Analisis estatico
flutter analyze

# Formatear codigo
dart format lib/ test/

# Ver dependencias desactualizadas
flutter pub outdated
```

## Convenciones de Codigo

- **Archivos**: snake_case (`transaction_repository.dart`)
- **Clases**: PascalCase (`TransactionRepository`)
- **Variables**: camelCase (`getMonthlyBalance`)
- **Arquitectura**: Feature-first + Repository pattern + Offline-first

## Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'feat: descripcion'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Documentacion Adicional

- [CHANGELOG.md](CHANGELOG.md) - Historial de versiones
- [CLAUDE.md](CLAUDE.md) - Guia para desarrollo con Claude
- [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) - Tutorial paso a paso
- [docs/USER_MANUAL.md](docs/USER_MANUAL.md) - Manual de usuario

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

## Contacto

- **Autor**: Alvaro
- **GitHub**: [@alvaretto](https://github.com/alvaretto)

---

**Version**: 1.9.0
**Moneda por defecto**: COP (Peso Colombiano)
**Ultima actualizacion**: 2026-01-03
