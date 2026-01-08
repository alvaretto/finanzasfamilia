import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../network/supabase_client.dart';
import '../services/notification_service.dart';

class AppInitializationResult {
  final String? errorMessage;

  const AppInitializationResult({this.errorMessage});

  bool get hasError => errorMessage != null;
}

class AppInitializer {
  static Future<AppInitializationResult> initialize() async {
    await initializeDateFormatting('es');

    await _configureOrientation();

    final envError = await _loadEnvironment();
    if (envError != null) {
      return AppInitializationResult(errorMessage: envError);
    }

    final supabaseError = await _initializeSupabase();

    await _initializeNotifications();

    return AppInitializationResult(errorMessage: supabaseError);
  }

  static Future<void> _configureOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (error) {
      debugPrint('Warning: Could not set preferred orientations: $error');
    }
  }

  static Future<String?> _loadEnvironment() async {
    try {
      await dotenv.load(fileName: '.env');
      return null;
    } catch (error) {
      debugPrint('Error loading .env file: $error');
      return 'Error cargando configuración';
    }
  }

  static Future<String?> _initializeSupabase() async {
    try {
      await SupabaseClientProvider.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout inicializando Supabase');
        },
      );
      return null;
    } catch (error) {
      debugPrint('Error initializing Supabase: $error');
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  static Future<void> _initializeNotifications() async {
    try {
      await NotificationService.instance.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Warning: Notification service initialization timed out');
        },
      );
    } catch (error) {
      debugPrint('Warning: Could not initialize notifications: $error');
    }
  }
}
