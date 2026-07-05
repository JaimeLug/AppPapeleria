import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credenciales recordadas para el inicio de sesión rápido.
class SavedCredentials {
  final String email;
  final String password;
  const SavedCredentials(this.email, this.password);
}

/// Guarda de forma cifrada (en Windows usa DPAPI, ligado a la cuenta del SO)
/// el email y la contraseña cuando el usuario activa "Recordar mis datos".
/// Es opcional: si no se activa, no se guarda nada.
class CredentialStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kEmail = 'saved_email';
  static const String _kPassword = 'saved_password';
  static const String _kRemember = 'remember_credentials';

  static Future<void> save(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
    await _storage.write(key: _kRemember, value: 'true');
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
    await _storage.write(key: _kRemember, value: 'false');
  }

  static Future<SavedCredentials?> load() async {
    final remember = await _storage.read(key: _kRemember);
    if (remember != 'true') return null;

    final email = await _storage.read(key: _kEmail);
    final password = await _storage.read(key: _kPassword);
    if (email == null || password == null) return null;

    return SavedCredentials(email, password);
  }
}
