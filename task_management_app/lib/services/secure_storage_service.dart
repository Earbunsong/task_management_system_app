import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _jwtKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userRoleKey = 'user_role';
  static const _userTypeKey = 'user_type';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Token methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: _jwtKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _jwtKey);
  }

  // User info methods
  Future<void> saveUserInfo({
    required String id,
    required String email,
    required String name,
    required String role,
    required String userType,
  }) async {
    await _storage.write(key: _userIdKey, value: id);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userRoleKey, value: role);
    await _storage.write(key: _userTypeKey, value: userType);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<String?> getUserEmail() async {
    return _storage.read(key: _userEmailKey);
  }

  Future<String?> getUserName() async {
    return _storage.read(key: _userNameKey);
  }

  Future<String?> getUserRole() async {
    return _storage.read(key: _userRoleKey);
  }

  Future<String?> getUserType() async {
    return _storage.read(key: _userTypeKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userRoleKey);
    await _storage.delete(key: _userTypeKey);
  }
}
