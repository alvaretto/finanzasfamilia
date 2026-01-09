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
import 'data/local/daos/categories_dao.dart';
import 'data/local/seeders/category_seeder.dart';
import 'data/sync/sync.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicializar Firebase
    await Firebase.initializeApp();

    // Configurar Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Cargar variables de entorno
    await dotenv.load(fileName: '.env');

    // Validar configuración
    if (!EnvConfig.isValid) {
      throw Exception(
        'Configuración inválida. Verifica SUPABASE_URL y SUPABASE_ANON_KEY en .env',
      );
    }

    // Inicializar Supabase
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );

    // Inicializar PowerSync con Supabase
    await PowerSyncDatabaseManager.instance.initialize(
      Supabase.instance.client,
    );

    // Inicializar base de datos local y sembrar categorías
    final db = AppDatabase();
    final categoriesDao = CategoriesDao(db);
    await seedCategories(categoriesDao);

    runApp(
      ProviderScope(
        overrides: [
          // Proveer la base de datos inicializada
          _databaseProvider.overrideWithValue(db),
        ],
        child: const FinanzasFamiliaresApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

/// Provider interno para la base de datos
final _databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Debe ser overrideado');
});

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
