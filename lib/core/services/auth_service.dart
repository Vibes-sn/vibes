import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _log('signUp start email=$email');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = response.user;
      if (user != null) {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
        });
        _log('profile upserted id=${user.id}');
      }
      _log('signUp success user=${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      _log('signUp auth error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _log('signUp error: $e');
      throw Exception('Une erreur est survenue, réessaie.');
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _log('signIn start email=$email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        final fullName =
            (user.userMetadata?['full_name'] as String?) ??
            user.email?.split('@').first ??
            'Viber';
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
        });
        _log('profile upserted id=${user.id}');
      }
      _log('signIn success user=${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      _log('signIn auth error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _log('signIn error: $e');
      throw Exception('Impossible de te connecter, réessaie.');
    }
  }

  Future<void> signOut() async {
    try {
      _log('signOut start');
      await _client.auth.signOut();
      _log('signOut success');
    } on AuthException catch (e) {
      _log('signOut auth error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _log('signOut error: $e');
      throw Exception('Erreur lors de la déconnexion.');
    }
  }

  Future<String> toggleRole(String role) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }
    try {
      _log('toggleRole start user=${user.id} role=$role');
      final updated = await _client
          .from('profiles')
          .update({'role': role})
          .eq('id', user.id)
          .select('role')
          .maybeSingle();
      await _client.auth.refreshSession();
      if (updated == null) {
        throw Exception('Aucun profil mis à jour (RLS ou profil manquant).');
      }
      final newRole = updated['role'] as String? ?? role;
      _log('toggleRole success role=$newRole');
      return newRole;
    } on PostgrestException catch (e) {
      _log('toggleRole error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _log('toggleRole error: $e');
      throw Exception('Impossible de changer le rôle.');
    }
  }

  void _log(String message) {
    debugPrint('[AuthService] $message');
  }
}
