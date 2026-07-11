import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credenciales de conexión a Supabase de este dispositivo.
class SupabaseCredentials {
  final String url;
  final String anonKey;
  const SupabaseCredentials(this.url, this.anonKey);
}

/// Guarda de forma cifrada (DPAPI en Windows) la URL y la llave anon de
/// Supabase que ingresa el usuario en el asistente de bienvenida.
///
/// Prioridad al arrancar (ver main.dart): estas credenciales guardadas SI
/// existen; si no, se usa el `.env` empaquetado como default (la base actual).
/// Así la instalación de fábrica funciona sola, y un cliente con su propia
/// base puede sobrescribirla sin reinstalar.
class SupabaseCredentialsStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kUrl = 'supabase_url';
  static const String _kKey = 'supabase_anon_key';

  static Future<void> save(String url, String anonKey) async {
    await _storage.write(key: _kUrl, value: url.trim());
    await _storage.write(key: _kKey, value: anonKey.trim());
  }

  static Future<SupabaseCredentials?> load() async {
    final url = await _storage.read(key: _kUrl);
    final key = await _storage.read(key: _kKey);
    if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
      return SupabaseCredentials(url, key);
    }
    return null;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kUrl);
    await _storage.delete(key: _kKey);
  }
}
