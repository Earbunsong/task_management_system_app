import 'package:flutter/material.dart';
import 'package:task_management_app/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _service = PaymentService();
  bool _loading = false;
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sub = await _service.getSubscription();
      setState(() => _subscription = sub);
    } catch (_) {}
  }

  Future<void> _checkout(String plan) async {
    setState(() => _loading = true);
    try {
      final url = await _service.createCheckoutSession(plan: plan);
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _loading = true);
    try {
      await _service.cancelSubscription();
      await _load();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _subscription?['plan_type']?.toString() ?? 'Basic';
    final status = _subscription?['payment_status']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current plan: $plan'),
            Text('Status: $status'),
            const SizedBox(height: 20),
            Wrap(spacing: 12, children: [
              ElevatedButton(
                onPressed: _loading ? null : () => _checkout('monthly'),
                child: const Text('Upgrade Monthly'),
              ),
              ElevatedButton(
                onPressed: _loading ? null : () => _checkout('annual'),
                child: const Text('Upgrade Annual'),
              ),
              OutlinedButton(
                onPressed: _loading ? null : _cancel,
                child: const Text('Cancel Subscription'),
              )
            ]),
          ],
        ),
      ),
    );
  }
}
