import 'package:task_management_app/models/app_notification.dart';
import 'package:task_management_app/services/api_client.dart';

class NotificationService {
  final _client = ApiClient()..init();

  Future<List<AppNotification>> getNotifications() async {
    final res = await _client.dio.get('/notifications/');
    final list = res.data as List<dynamic>;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(int id) async {
    await _client.dio.patch('/notifications/$id/read/');
  }

  Future<void> registerFcmToken(String token) async {
    await _client.dio.post('/notifications/register-token/', data: {
      'token': token,
    });
  }
}
