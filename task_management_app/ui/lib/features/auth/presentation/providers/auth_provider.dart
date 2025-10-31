import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/secure_storage.dart';
import '../../../../core/dio_client.dart';
import '../../data/auth_api.dart';

class AuthState {
  const AuthState({this.token});
  final String? token;
  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState());
  final AuthApi _api;

  Future<void> loadToken() async {
    final t = await SecureStorage.getToken();
    state = AuthState(token: t);
  }

  Future<bool> login(String email, String password) async {
    final token = await _api.login(email: email, password: password);
    await SecureStorage.setToken(token);
    state = AuthState(token: token);
    return true;
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    state = const AuthState(token: null);
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(SecureStorage.getToken)..addAuthInterceptor();
});

final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthApi(client);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(authApiProvider);
  return AuthNotifier(api);
});
