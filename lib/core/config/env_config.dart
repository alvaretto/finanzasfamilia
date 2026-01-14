import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración del entorno desde .env
class EnvConfig {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get powerSyncUrl =>
      dotenv.env['POWERSYNC_URL'] ?? '';

  /// Valida que las variables requeridas estén configuradas
  static bool get isValid =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Valida si PowerSync está configurado
  static bool get isPowerSyncConfigured => powerSyncUrl.isNotEmpty;
}
