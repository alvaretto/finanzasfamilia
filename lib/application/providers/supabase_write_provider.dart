import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/supabase_write_service.dart';

/// Provider para el servicio de escritura directa a Supabase
///
/// ARQUITECTURA: Online-first writes
/// - Writes van directamente a Supabase (no pasan por PowerSync)
/// - PowerSync solo descarga datos → Drift local
/// - Lecturas desde Drift (rápido)
final supabaseWriteServiceProvider = Provider<SupabaseWriteService>((ref) {
  return SupabaseWriteService(Supabase.instance.client);
});

/// Provider para verificar si el usuario está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});

/// Provider para obtener el ID del usuario actual
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
