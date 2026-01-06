/// Configuración global de tests para Finanzas Familiares
///
/// Este archivo se ejecuta automáticamente antes de TODOS los tests.
/// Configura el ambiente de testing con Supabase en modo test.
///
/// Uso: Flutter detecta automáticamente este archivo y lo ejecuta.
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';

/// Función que Flutter ejecuta automáticamente antes de todos los tests
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 1. Asegurar que el binding de Flutter está inicializado
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar localización para DateFormat (español)
  await initializeDateFormatting('es', null);

  // 3. Habilitar modo test de Supabase GLOBALMENTE
  // Esto previene que cualquier test intente usar Supabase real
  SupabaseClientProvider.enableTestMode();

  // 4. Resetear singleton de database para evitar path_provider
  AppDatabase.resetInstance();

  // 5. Ejecutar los tests
  await testMain();

  // 6. Cleanup después de todos los tests
  SupabaseClientProvider.reset();
}
