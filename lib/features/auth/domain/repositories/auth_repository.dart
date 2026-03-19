import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password);
  
  /// Sign out the current user
  Future<void> signOut();
  
  /// Get the current logged in user, if any
  User? getCurrentUser();
  
  /// Stream of authentication state changes
  Stream<AuthState> authStateChanges();
}
