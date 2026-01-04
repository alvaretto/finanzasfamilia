import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/supabase_client.dart';
import 'core/services/notification_service.dart';
import 'shared/providers/providers.dart';

/// Indica si la app está inicializada correctamente
bool _isInitialized = false;
String? _initError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de localización para fechas en español
  await initializeDateFormatting('es');

  // Orientacion preferida - no crítico, puede fallar
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Warning: Could not set preferred orientations: $e');
  }

  // Cargar variables de entorno - crítico pero con fallback
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    _initError = 'Error cargando configuración';
  }

  // Inicializar Supabase - crítico pero con timeout
  if (_initError == null) {
    try {
      await SupabaseClientProvider.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout inicializando Supabase');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      _initError = 'Error de conexión. Verifica tu internet.';
      // Continuar sin Supabase - modo offline
      _isInitialized = true;
    }
  }

  // Inicializar Notificaciones - no crítico
  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Warning: Notification service initialization timed out');
      },
    );
  } catch (e) {
    debugPrint('Warning: Could not initialize notifications: $e');
    // Continuar sin notificaciones
  }

  runApp(
    ProviderScope(
      child: FinanzasFamiliaresApp(initError: _initError),
    ),
  );
}

class FinanzasFamiliaresApp extends ConsumerWidget {
  final String? initError;

  const FinanzasFamiliaresApp({super.key, this.initError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si hay error de inicialización, mostrar pantalla de error
    if (initError != null) {
      return MaterialApp(
        title: 'Finanzas Familiares',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: _ErrorScreen(message: initError!),
      );
    }

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Finanzas Familiares',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}

/// Pantalla de error para mostrar cuando la inicialización falla
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Error al iniciar',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Reiniciar la app
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
