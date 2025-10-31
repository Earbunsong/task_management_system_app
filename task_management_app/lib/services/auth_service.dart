import 'package:dio/dio.dart';
import 'package:task_management_app/services/api_client.dart';
import 'package:task_management_app/services/secure_storage_service.dart';
import 'package:task_management_app/models/user.dart';

class AuthService {
  final _client = ApiClient();
  final _storage = SecureStorageService();

  AuthService() {
    _client.init();
  }

  Future<void> register({required String email, required String password}) async {
    await _client.dio.post('/auth/register/', data: {
      'email': email,
      'password': password,
    });
  }

  Future<UserProfile> login({required String email, required String password}) async {
    final res = await _client.dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });

    final token = res.data['token'] as String? ?? res.data['access'] as String?;
    if (token == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Token not found in response');
    }

    await _storage.saveToken(token);

    // Save user info if provided in response
    final userData = res.data['user'] as Map<String, dynamic>?;
    if (userData != null) {
      final user = UserProfile.fromJson(userData);
      await _storage.saveUserInfo(
        id: user.id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
        userType: user.userType,
      );
      return user;
    } else {
      // If user data not in login response, fetch profile
      return await getProfile();
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout/');
    } finally {
      await _storage.clear();
    }
  }

  Future<UserProfile> getProfile() async {
    final res = await _client.dio.get('/auth/profile/');
    final user = UserProfile.fromJson(res.data as Map<String, dynamic>);

    // Save user info to storage
    await _storage.saveUserInfo(
      id: user.id.toString(),
      email: user.email,
      name: user.name,
      role: user.role,
      userType: user.userType,
    );

    return user;
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    await _client.dio.put('/auth/profile/', data: payload);
  }

  Future<void> forgotPassword(String email) async {
    await _client.dio.post('/auth/forgot-password/', data: {'email': email});
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _client.dio.post('/auth/reset-password/', data: {
      'token': token,
      'password': newPassword,
    });
  }
}
