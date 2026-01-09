import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'data/local/database.dart';
import 'application/providers/database_provider.dart';
import 'data/local/daos/accounts_dao.dart';
import 'data/local/daos/categories_dao.dart';
import 'data/local/seeders/accounts_seeder.dart';
import 'data/local/seeders/category_seeder.dart';
import 'data/sync/sync.dart';
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

    // Inicializar Supabase
    debugPrint('[INIT] Inicializando Supabase...');
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
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

    // Inicializar base de datos local y sembrar datos
    debugPrint('[INIT] Inicializando DB local...');
    final db = AppDatabase();
    final categoriesDao = CategoriesDao(db);
    final accountsDao = AccountsDao(db);
    await seedCategories(categoriesDao);
    await seedAccounts(accountsDao, categoriesDao);
    debugPrint('[INIT] DB local OK');

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

class FinanzasFamiliaresApp extends StatelessWidget {
  const FinanzasFamiliaresApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Verde oscuro
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF1B5E20).withValues(alpha: 0.2),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
