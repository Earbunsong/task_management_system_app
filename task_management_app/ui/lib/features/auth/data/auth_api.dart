import 'package:dio/dio.dart';
import '../../../../core/dio_client.dart';

class AuthApi {
  AuthApi(DioClient client) : _dio = client.dio;
  final Dio _dio;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login/',
      data: {'email': email, 'password': password},
    );
    // Expect { token: '...' } or similar; adjust to your API
    return res.data['token'] as String;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/auth/register/',
      data: {'name': name, 'email': email, 'password': password},
    );
  }
}
