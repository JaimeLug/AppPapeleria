/// Custom exception for authentication-related errors
/// 
/// Thrown when Google Cloud authentication fails due to:
/// - Expired access tokens
/// - Invalid credentials
/// - 401 Unauthorized responses
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
