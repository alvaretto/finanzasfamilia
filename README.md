# Finanzas Familiares AS

Una aplicacion de finanzas personales y familiares multiplataforma, offline-first, desarrollada con Flutter y Supabase.

## Caracteristicas Principales

- **Multiplataforma**: Android, iOS, Linux, Windows, macOS, Web
- **Offline-First**: Funciona sin conexion, sincroniza automaticamente
- **Gestion Familiar**: Comparte finanzas con tu familia con control de permisos
- **Presupuestos Inteligentes**: Define limites y recibe alertas
- **Metas de Ahorro**: Visualiza tu progreso hacia objetivos financieros
- **Analytics**: Graficos, reportes y insights sobre tus habitos

## Capturas de Pantalla

*Proximamente*

## Requisitos del Sistema

### Para Desarrollo
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code
- Git

### Para Uso
- **Android**: 7.0+ (API 24)
- **Linux**: Ubuntu 20.04+ / Manjaro / Fedora

## Instalacion

### Desde Codigo Fuente

```bash
# Clonar repositorio
git clone https://github.com/tuusuario/finanzas-familiares-as.git
cd finanzas-familiares-as

# Instalar dependencias
flutter pub get

# Generar codigo (freezed, drift, riverpod)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en modo debug
flutter run
```

### Configurar Variables de Entorno

Crea un archivo `.env` en la raiz:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

### Build para Produccion

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# Linux Desktop
flutter build linux --release
```

## Estructura del Proyecto

```
lib/
├── core/               # Infraestructura compartida
│   ├── database/       # Drift (SQLite local)
│   ├── network/        # Supabase client
│   └── theme/          # Design system
├── features/           # Modulos de funcionalidad
│   ├── auth/           # Autenticacion
│   ├── accounts/       # Cuentas bancarias
│   ├── transactions/   # Ingresos/gastos
│   ├── budgets/        # Presupuestos
│   ├── goals/          # Metas de ahorro
│   ├── reports/        # Graficos y analytics
│   ├── family/         # Gestion familiar
│   └── settings/       # Configuracion
└── shared/             # Componentes compartidos
```

## Stack Tecnologico

| Componente | Tecnologia |
|------------|-----------|
| Framework | Flutter 3.24+ |
| State Management | Riverpod 3.0 |
| Database Local | Drift + SQLite |
| Backend | Supabase |
| Navegacion | go_router |
| Modelos | freezed |
| Graficos | fl_chart |
| Auth Local | local_auth (biometria) |

## Desarrollo

### Comandos Utiles

```bash
# Generar codigo
dart run build_runner watch

# Tests
flutter test

# Tests con coverage
flutter test --coverage

# Analisis estatico
flutter analyze

# Formatear codigo
dart format lib/ test/
```

### Convenciones

- **Archivos**: snake_case
- **Clases**: PascalCase
- **Variables**: camelCase
- **Arquitectura**: Feature-first + Repository pattern

## Roadmap

- [x] Fase 0: Setup inicial
- [ ] Fase 1: Core MVP (Auth, Cuentas, Transacciones)
- [ ] Fase 2: Presupuestos y Metas
- [ ] Fase 3: Gestion Familiar
- [ ] Fase 4: Analytics Avanzados
- [ ] Fase 5: Lanzamiento

Ver [PLAN_DESARROLLO.md](PLAN_DESARROLLO.md) para detalles completos.

## Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Add: nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

## Contacto

- **Autor**: [Tu nombre]
- **Email**: [tu@email.com]
- **GitHub**: [github.com/tuusuario](https://github.com/tuusuario)
