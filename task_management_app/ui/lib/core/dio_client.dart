import 'package:dio/dio.dart';
import 'config.dart';

class DioClient {
  DioClient(this._tokenGetter)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final Future<String?> Function() _tokenGetter;
  final Dio dio;

  void addAuthInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenGetter();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}
