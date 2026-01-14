import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_provider.dart';
import '../../data/repositories/drift_user_settings_repository.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../../domain/services/user_settings_service.dart';

part 'user_settings_provider.g.dart';

/// Provider del repositorio de configuración de usuario
@Riverpod(keepAlive: true)
UserSettingsRepository userSettingsRepository(UserSettingsRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftUserSettingsRepository(database);
}

/// Provider del servicio de configuración de usuario
@Riverpod(keepAlive: true)
UserSettingsService userSettingsService(UserSettingsServiceRef ref) {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return UserSettingsService(repository);
}

/// Provider de la configuración del usuario actual
@Riverpod(keepAlive: true)
Stream<UserSettings?> userSettings(UserSettingsRef ref) {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return repository.watchSettings();
}

/// Provider para inicializar settings en el primer login
@riverpod
Future<void> initializeUserSettings(InitializeUserSettingsRef ref) async {
  final service = ref.watch(userSettingsServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw StateError('Usuario no autenticado');
  }

  await service.createInitialSettings(userId);
}


