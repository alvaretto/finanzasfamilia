import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/family_model.dart';

class FamilyRepository {
  final _supabase = Supabase.instance.client;

  /// Obtener familias del usuario
  Future<List<FamilyModel>> getFamilies(String userId) async {
    // Obtener IDs de familias donde el usuario es miembro
    final memberOf = await _supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', userId);

    final familyIds =
        (memberOf as List).map((m) => m['family_id'] as String).toList();

    if (familyIds.isEmpty) return [];

    // Obtener familias con miembros
    final response = await _supabase
        .from('families')
        .select('''
          *,
          family_members (
            *,
            profiles (display_name, avatar_url)
          )
        ''')
        .inFilter('id', familyIds)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FamilyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener familia por ID
  Future<FamilyModel?> getFamilyById(String familyId) async {
    final response = await _supabase
        .from('families')
        .select('''
          *,
          family_members (
            *,
            profiles (display_name, avatar_url)
          )
        ''')
        .eq('id', familyId)
        .maybeSingle();

    if (response == null) return null;
    return FamilyModel.fromJson(response);
  }

  /// Crear familia
  Future<FamilyModel> createFamily(String name, String ownerId) async {
    // Crear familia
    final familyResponse = await _supabase
        .from('families')
        .insert({
          'name': name,
          'owner_id': ownerId,
        })
        .select()
        .single();

    final familyId = familyResponse['id'] as String;

    // Agregar propietario como miembro
    await _supabase.from('family_members').insert({
      'family_id': familyId,
      'user_id': ownerId,
      'role': 'owner',
    });

    // Retornar familia completa
    final family = await getFamilyById(familyId);
    return family!;
  }

  /// Unirse a familia con código
  Future<FamilyModel?> joinFamily(String inviteCode, String userId) async {
    // Buscar familia por código
    final familyResponse = await _supabase
        .from('families')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .maybeSingle();

    if (familyResponse == null) return null;

    final familyId = familyResponse['id'] as String;

    // Verificar si ya es miembro
    final existing = await _supabase
        .from('family_members')
        .select()
        .eq('family_id', familyId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Ya es miembro, solo retornar la familia
      return getFamilyById(familyId);
    }

    // Agregar como miembro
    await _supabase.from('family_members').insert({
      'family_id': familyId,
      'user_id': userId,
      'role': 'member',
    });

    return getFamilyById(familyId);
  }

  /// Actualizar nombre de familia
  Future<void> updateFamilyName(String familyId, String name) async {
    await _supabase.from('families').update({'name': name}).eq('id', familyId);
  }

  /// Regenerar código de invitación
  Future<String> regenerateInviteCode(String familyId) async {
    final response = await _supabase.rpc('regenerate_invite_code', params: {
      'family_id_param': familyId,
    });
    return response as String;
  }

  /// Cambiar rol de miembro
  Future<void> updateMemberRole(
    String memberId,
    FamilyRole role,
  ) async {
    await _supabase
        .from('family_members')
        .update({'role': role.name})
        .eq('id', memberId);
  }

  /// Eliminar miembro
  Future<void> removeMember(String memberId) async {
    await _supabase.from('family_members').delete().eq('id', memberId);
  }

  /// Salir de familia
  Future<void> leaveFamily(String familyId, String userId) async {
    await _supabase
        .from('family_members')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }

  /// Eliminar familia
  Future<void> deleteFamily(String familyId) async {
    // Primero eliminar miembros
    await _supabase.from('family_members').delete().eq('family_id', familyId);
    // Luego eliminar familia
    await _supabase.from('families').delete().eq('id', familyId);
  }

  /// Stream de familias del usuario
  Stream<List<FamilyModel>> watchFamilies(String userId) {
    return _supabase
        .from('family_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((_) => getFamilies(userId));
  }
}
