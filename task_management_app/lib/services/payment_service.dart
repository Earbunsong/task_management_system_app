import 'package:dio/dio.dart';
import 'package:task_management_app/services/api_client.dart';

class PaymentService {
  final _client = ApiClient()..init();

  Future<String> createCheckoutSession({required String plan}) async {
    final res = await _client.dio.post('/payment/create-session/', data: {
      'plan': plan, // 'monthly' or 'annual'
    });
    // Assume backend returns { url: 'https://checkout.stripe.com/...'}
    return (res.data['url'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getSubscription() async {
    final res = await _client.dio.get('/payment/subscription/');
    return res.data as Map<String, dynamic>;
  }

  Future<void> cancelSubscription() async {
    await _client.dio.post('/payment/cancel/');
  }

  Future<List<dynamic>> getHistory() async {
    final res = await _client.dio.get('/payment/history/');
    return res.data as List<dynamic>;
  }
}
