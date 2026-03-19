import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepositoryImpl(this._supabase);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // Map common Supabase Auth exceptions to friendly messages
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Credenciales incorrectas. Verifica tu email y contraseña.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  @override
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}
