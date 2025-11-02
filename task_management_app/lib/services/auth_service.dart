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

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _client.dio.post('/auth/register/', data: {
        'username': name,
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map && errors.containsKey('errors')) {
          final errorMap = errors['errors'] as Map;
          // Combine all error messages
          final messages = <String>[];
          errorMap.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            }
          });
          throw Exception(messages.join('\n'));
        } else if (errors is Map && errors.containsKey('message')) {
          throw Exception(errors['message']);
        }
      }
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  Future<UserProfile> login({required String email, required String password}) async {
    try {
      final res = await _client.dio.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });

      final token = res.data['access'] as String?;
      if (token == null) {
        throw Exception('Token not found in response');
      }

      await _storage.saveToken(token);

      // JWT login doesn't return user data, so fetch profile
      return await getProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('detail')) {
            throw Exception(errors['detail']);
          } else if (errors.containsKey('message')) {
            throw Exception(errors['message']);
          }
        }
      }
      throw Exception(e.message ?? 'Login failed');
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
