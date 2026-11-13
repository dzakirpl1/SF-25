import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';
import '../../../core/errors/app_error.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<UserProfile?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
