import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository_impl.dart';

// --- Repositories ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepositoryImpl(supabaseClient);
});

// --- State Providers ---

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

// --- Controllers ---

class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});

  LoginState copyWith({bool? isLoading, String? errorMessage}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // We want to allow nulling the error message explicitly
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _repository;

  LoginController(this._repository) : super(const LoginState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithEmail(email, password);
      // Success: No need to set isLoading false because authStateChanges will trigger a redirect anyway.
      // But for completeness:
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      // The repository throws friendly exceptions we can display directly
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      // Ignored for now or could show a snackbar globally
      // print('Error en signOut: $e');
    }
  }
}

final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginController(repository);
});
