import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(title: Text('Current Plan'), subtitle: Text('Basic')),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Pro'),
          ),
          const Divider(height: 32),
          const ListTile(title: Text('Payment History')),
          ...List.generate(
            3,
            (i) => const ListTile(
              title: Text('Stripe: \$9.99/month'),
              subtitle: Text('Jan 10, 2025'),
            ),
          ),
        ],
      ),
    );
  }
}
