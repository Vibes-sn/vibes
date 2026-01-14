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
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } catch (e) {
      throw Exception('Inscription échouée : $e');
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Connexion échouée : $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Déconnexion échouée : $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.vibes://callback',
      );
    } catch (e) {
      final msg = '$e';
      if (msg.toLowerCase().contains('provider is not enabled')) {
        throw Exception(
          'Google OAuth non activé dans Supabase (Auth > Settings > External OAuth).',
        );
      }
      throw Exception('Connexion Google échouée : $msg');
    }
  }

  Future<void> signInWithPhone(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } catch (e) {
      throw Exception('Connexion par téléphone échouée : $e');
    }
  }

  Future<void> verifyOtp(String phone, String token) async {
    try {
      await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      throw Exception('Vérification OTP échouée : $e');
    }
  }
}
