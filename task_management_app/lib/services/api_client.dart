import 'package:dio/dio.dart';
import 'package:task_management_app/config.dart';
import 'package:task_management_app/services/secure_storage_service.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final _storage = SecureStorageService();

  void init() {
    dio.interceptors.clear();

    // Add logging interceptor
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
      logPrint: (obj) => print('[API] $obj'),
    ));

    // Add auth interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('[API] Request: ${options.method} ${options.uri}');
        print('[API] Headers: ${options.headers}');
        print('[API] Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('[API] Response [${response.statusCode}]: ${response.data}');
        handler.next(response);
      },
      onError: (DioException e, handler) async {
        print('[API] Error [${e.response?.statusCode}]: ${e.response?.data}');
        print('[API] Error Message: ${e.message}');

        // If unauthorized, clear token so user can re-login
        if (e.response?.statusCode == 401) {
          await _storage.clear();
        }
        handler.next(e);
      },
    ));
  }
}
