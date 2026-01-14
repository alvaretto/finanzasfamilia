import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'core/storage/secure_local_storage.dart';
import 'data/local/database.dart';
import 'application/providers/database_provider.dart';
import 'application/services/data_seeding_service.dart';
import 'data/sync/sync.dart';
import 'application/services/notification_service.dart';
import 'application/services/in_app_update_service.dart';
import 'application/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    debugPrint('[INIT] Inicializando Firebase...');
    await Firebase.initializeApp();
    debugPrint('[INIT] Firebase OK');

    // Configurar Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Cargar variables de entorno
    debugPrint('[INIT] Cargando .env...');
    await dotenv.load(fileName: '.env');
    debugPrint('[INIT] .env OK - URL: ${EnvConfig.supabaseUrl}');

    // Validar configuración
    if (!EnvConfig.isValid) {
      throw Exception(
        'Configuración inválida. Verifica SUPABASE_URL y SUPABASE_ANON_KEY en .env',
      );
    }
    debugPrint('[INIT] Config válida');

    // Inicializar Supabase con almacenamiento seguro persistente
    // CRÍTICO: SharedPreferences (default) se borra al desinstalar.
    // SecureLocalStorage usa Android Keystore/iOS Keychain que persisten.
    debugPrint('[INIT] Inicializando Supabase con almacenamiento seguro...');
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        detectSessionInUri: true,
        localStorage: SecureLocalStorage(),
      ),
      debug: kDebugMode,
    );
    debugPrint('[INIT] Supabase OK');

    // Inicializar PowerSync con Supabase (con timeout)
    debugPrint('[INIT] Inicializando PowerSync...');
    await PowerSyncDatabaseManager.instance.initialize(
      Supabase.instance.client,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[INIT] PowerSync timeout - continuando sin sync');
      },
    );
    debugPrint('[INIT] PowerSync OK');

    // Inicializar base de datos local
    // ARQUITECTURA: Online-first - PowerSync descarga, escrituras van a Supabase
    debugPrint('[INIT] Inicializando DB local...');
    final db = AppDatabase();

    // Sembrar datos iniciales si la DB está vacía (cualquier usuario)
    debugPrint('[INIT] Verificando seeding...');
    final seedingService = DataSeedingService(db);
    await seedingService.seedIfEmpty();
    debugPrint('[INIT] DB local OK');

    // Inicializar servicio de notificaciones
    debugPrint('[INIT] Inicializando notificaciones...');
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
    debugPrint('[INIT] Notificaciones OK');

    // Verificar actualizaciones disponibles en Play Store
    // Nota: No crítico, puede fallar en desarrollo/emuladores
    debugPrint('[INIT] Verificando actualizaciones...');
    try {
      await InAppUpdateService().checkAndPromptUpdate();
      debugPrint('[INIT] In-App Update OK');
    } catch (e) {
      debugPrint('[INIT] In-App Update no disponible: $e');
    }

    runApp(
      ProviderScope(
        overrides: [
          // Proveer la base de datos inicializada al provider de Riverpod
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const FinanzasFamiliaresApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('[INIT ERROR] $e');
    debugPrint('[INIT STACK] $stack');
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
    // Mostrar app con error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error de inicialización:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    ));
  }
}

class FinanzasFamiliaresApp extends ConsumerStatefulWidget {
  const FinanzasFamiliaresApp({super.key});

  @override
  ConsumerState<FinanzasFamiliaresApp> createState() =>
      _FinanzasFamiliaresAppState();
}

class _FinanzasFamiliaresAppState extends ConsumerState<FinanzasFamiliaresApp>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  String? _lastProcessedLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Iniciar escucha activa de deep links inmediatamente
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Inicializa listener activo para deep links entrantes
  /// CRÍTICO: Esto captura el callback OAuth cuando el navegador redirige de vuelta
  void _initDeepLinkListener() {
    // Escuchar links entrantes en tiempo real (stream)
    _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('[DEEP_LINK] Link recibido en stream: $uri');
      _processDeepLink(uri);
    }, onError: (e) {
      debugPrint('[DEEP_LINK] Error en stream: $e');
    });

    // También verificar si hay un link inicial (app abierta desde link)
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        debugPrint('[DEEP_LINK] Link inicial: $uri');
        _processDeepLink(uri);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cuando la app vuelve al foreground, verificar si hay un deep link pendiente
      _checkPendingDeepLink();
    }
  }

  Future<void> _checkPendingDeepLink() async {
    // Solo en mobile
    if (kIsWeb) return;

    // Si ya hay sesión, no procesar
    if (Supabase.instance.client.auth.currentSession != null) return;

    try {
      final uri = await _appLinks.getLatestLink();
      if (uri == null) return;
      _processDeepLink(uri);
    } catch (e) {
      debugPrint('[DEEP_LINK] Error procesando link pendiente: $e');
    }
  }

  /// Procesa un deep link de OAuth
  Future<void> _processDeepLink(Uri uri) async {
    final uriString = uri.toString();

    // Evitar reprocesar el mismo link
    if (uriString == _lastProcessedLink) {
      debugPrint('[DEEP_LINK] Link ya procesado, ignorando');
      return;
    }

    // Verificar si es un callback OAuth
    if (uri.scheme == 'io.supabase.finanzasfamiliares' &&
        uri.host == 'login-callback') {
      debugPrint('[DEEP_LINK] Callback OAuth detectado');
      _lastProcessedLink = uriString;

      // El token puede estar en fragment (#) o query (?)
      if (uri.fragment.contains('access_token') ||
          uri.queryParameters.containsKey('access_token')) {
        try {
          debugPrint('[DEEP_LINK] Procesando token de acceso...');
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
          debugPrint('[DEEP_LINK] Sesión establecida correctamente');
        } catch (e) {
          debugPrint('[DEEP_LINK] Error estableciendo sesión: $e');
        }
      } else if (uri.fragment.contains('error') ||
          uri.queryParameters.containsKey('error')) {
        debugPrint('[DEEP_LINK] OAuth retornó error: ${uri.fragment}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Finanzas Familiares',
      debugShowCheckedModeBanner: false,
      // Soporte para español colombiano
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es'),
        Locale('en'),
      ],
      locale: const Locale('es', 'CO'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appThemeModeToFlutter(appThemeMode),
      home: const SplashScreen(),
    );
  }
}
