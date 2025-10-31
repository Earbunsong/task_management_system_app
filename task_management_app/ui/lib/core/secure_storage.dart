import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _keyToken = 'jwt_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _keyToken);
  }
}
