import 'package:task_management_app/services/api_client.dart';

class PaymentService {
  final _client = ApiClient()..init();

  // Stripe payment methods
  Future<String> createCheckoutSession({required String plan}) async {
    final res = await _client.dio.post('/payment/create-session/', data: {
      'plan': plan, // 'monthly' or 'annual'
    });
    // Assume backend returns { url: 'https://checkout.stripe.com/...'}
    return (res.data['url'] as String?) ?? '';
  }

  // PayPal payment methods
  Future<String> createPayPalOrder({required String plan}) async {
    final res = await _client.dio.post('/payment/paypal/create-order/', data: {
      'plan': plan, // 'monthly' or 'annual'
    });
    // Backend returns { url: 'https://www.paypal.com/...', payment_id: '...' }
    return (res.data['url'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> executePayPalPayment({
    required String paymentId,
    required String payerId,
  }) async {
    final res = await _client.dio.post('/payment/paypal/execute-payment/', data: {
      'payment_id': paymentId,
      'payer_id': payerId,
    });
    return res.data as Map<String, dynamic>;
  }

  // KHQR payment methods
  Future<Map<String, dynamic>> createKHQRPayment({required String plan}) async {
    final res = await _client.dio.post('/payment/khqr/create-payment/', data: {
      'plan': plan, // 'monthly' or 'annual'
    });
    // Backend returns { qr_code: '...', qr_string: '...', transaction_id: '...' }
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkKHQRPaymentStatus({
    required String transactionId,
  }) async {
    final res = await _client.dio.post('/payment/khqr/check-status/', data: {
      'transaction_id': transactionId,
    });
    return res.data as Map<String, dynamic>;
  }

  // Common methods (work with both Stripe and PayPal)
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

  Future<Map<String, dynamic>> checkPaymentStatus() async {
    final res = await _client.dio.post('/payment/check-status/');
    return res.data as Map<String, dynamic>;
  }
}
