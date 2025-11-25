import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_management_app/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  final _service = PaymentService();
  bool _loading = false;
  Map<String, dynamic>? _subscription;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground (user returns from browser)
    if (state == AppLifecycleState.resumed) {
      // Check payment status first (handles local dev when webhooks don't work)
      _checkAndUpdatePaymentStatus();
    }
  }

  Future<void> _checkAndUpdatePaymentStatus() async {
    try {
      // Call the check status endpoint to verify and update payment
      final result = await _service.checkPaymentStatus();

      if (mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload subscription and history
        await _load();
      }
    } catch (e) {
      // If check fails, just reload normally
      if (mounted) {
        await _load();
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sub = await _service.getSubscription();
      final hist = await _service.getHistory();
      setState(() {
        _subscription = sub;
        _history = hist;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkout(String plan) async {
    // Show payment provider selection dialog
    final provider = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Pay with Stripe'),
              onTap: () => Navigator.of(ctx).pop('stripe'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: const Text('PayPal'),
              subtitle: const Text('Pay with PayPal account'),
              onTap: () => Navigator.of(ctx).pop('paypal'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.green),
              title: const Text('KHQR'),
              subtitle: const Text('Pay with Khmer QR'),
              onTap: () => Navigator.of(ctx).pop('khqr'),
            ),
          ],
        ),
      ),
    );

    if (provider == null) return;

    setState(() => _loading = true);
    try {
      if (provider == 'khqr') {
        // Handle KHQR payment
        final result = await _service.createKHQRPayment(plan: plan);
        setState(() => _loading = false);

        if (mounted) {
          // Show QR code dialog
          _showKHQRDialog(
            qrCode: result['qr_code'] ?? '',
            transactionId: result['transaction_id'] ?? '',
            amount: result['amount']?.toString() ?? '0',
            currency: result['currency'] ?? 'KHR',
          );
        }
      } else {
        // Handle Stripe/PayPal payment
        String url = '';

        if (provider == 'stripe') {
          url = await _service.createCheckoutSession(plan: plan);
        } else if (provider == 'paypal') {
          url = await _service.createPayPalOrder(plan: plan);
        }

        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open payment page'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showKHQRDialog({
    required String qrCode,
    required String transactionId,
    required String amount,
    required String currency,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KHQRPaymentDialog(
        qrCode: qrCode,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        onCheckStatus: () async {
          try {
            final result = await _service.checkKHQRPaymentStatus(
              transactionId: transactionId,
            );

            if (result['paid'] == true) {
              Navigator.of(ctx).pop();
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Payment successful!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Payment not yet received'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel your Pro subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await _service.cancelSubscription();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling subscription: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _subscription?['plan_type']?.toString().toUpperCase() ?? 'BASIC';
    final status = _subscription?['payment_status']?.toString() ?? 'inactive';
    final provider = _subscription?['payment_provider']?.toString() ?? '';
    final isPro = plan.toLowerCase() == 'pro';
    final isActive = status.toLowerCase() == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Payments'),
        elevation: 0,
      ),
      body: _loading && _subscription == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Plan Card
                      _buildCurrentPlanCard(plan, status, provider, isPro, isActive),
                      const SizedBox(height: 24),

                      // Upgrade Options
                      if (!isPro || !isActive) ...[
                        const Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPricingCards(),
                        const SizedBox(height: 24),
                      ],

                      // Cancel Button (only for active Pro users)
                      if (isPro && isActive) ...[
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _cancel,
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              'Cancel Subscription',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Payment History
                      const Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentHistory(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard(String plan, String status, String provider, bool isPro, bool isActive) {
    Color planColor = isPro ? Colors.amber : Colors.blue;
    IconData planIcon = isPro ? Icons.workspace_premium : Icons.person;

    // Payment provider icon and label
    IconData? providerIcon;
    String providerLabel = '';
    if (provider.isNotEmpty) {
      if (provider.toLowerCase() == 'stripe') {
        providerIcon = Icons.credit_card;
        providerLabel = 'Stripe';
      } else if (provider.toLowerCase() == 'paypal') {
        providerIcon = Icons.payment;
        providerLabel = 'PayPal';
      } else if (provider.toLowerCase() == 'khqr') {
        providerIcon = Icons.qr_code;
        providerLabel = 'KHQR';
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [planColor.withOpacity(0.1), planColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(planIcon, color: planColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$plan Plan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: planColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (providerIcon != null && providerLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(providerIcon, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    providerLabel,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (isPro) ...[
              _buildFeatureItem('Unlimited tasks', Icons.check_circle),
              _buildFeatureItem('Task assignment', Icons.check_circle),
              _buildFeatureItem('Media uploads', Icons.check_circle),
              _buildFeatureItem('Priority support', Icons.check_circle),
            ] else ...[
              _buildFeatureItem('Personal tasks only', Icons.task_alt),
              _buildFeatureItem('Limited uploads', Icons.cloud_upload),
              const SizedBox(height: 8),
              const Text(
                'Upgrade to Pro for unlimited features!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    return Row(
      children: [
        Expanded(
          child: _buildPricingCard(
            'Monthly',
            '\$9.99',
            '/month',
            'Billed monthly',
            () => _checkout('monthly'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPricingCard(
            'Annual',
            '\$99.99',
            '/year',
            'Save 17%!',
            () => _checkout('annual'),
            isRecommended: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String period,
    String subtitle,
    VoidCallback onTap, {
    bool isRecommended = false,
  }) {
    return Card(
      elevation: isRecommended ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRecommended ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isRecommended ? Colors.amber : Colors.grey,
                  fontWeight: isRecommended ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended ? Colors.amber : null,
                  foregroundColor: isRecommended ? Colors.white : null,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subscribe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No payment history yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((payment) {
        final amount = payment['amount']?.toString() ?? '0';
        final currency = payment['currency']?.toString().toUpperCase() ?? 'USD';
        final status = payment['status']?.toString() ?? 'unknown';
        final provider = payment['payment_provider']?.toString() ?? '';
        final createdAt = payment['created_at']?.toString() ?? '';
        final date = createdAt.isNotEmpty
            ? DateTime.tryParse(createdAt)
            : null;
        final formattedDate = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : 'N/A';

        Color statusColor;
        IconData statusIcon;
        switch (status.toLowerCase()) {
          case 'succeeded':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            break;
          case 'failed':
            statusColor = Colors.red;
            statusIcon = Icons.error;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        // Payment provider icon
        IconData providerIcon = Icons.payment;
        if (provider.toLowerCase() == 'stripe') {
          providerIcon = Icons.credit_card;
        } else if (provider.toLowerCase() == 'paypal') {
          providerIcon = Icons.payment;
        } else if (provider.toLowerCase() == 'khqr') {
          providerIcon = Icons.qr_code;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Row(
              children: [
                Text(
                  '\$$amount $currency',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (provider.isNotEmpty)
                  Icon(providerIcon, size: 16, color: Colors.grey),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate),
                if (provider.isNotEmpty)
                  Text(
                    'via ${provider.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KHQRPaymentDialog extends StatefulWidget {
  final String qrCode;
  final String transactionId;
  final String amount;
  final String currency;
  final Future<void> Function() onCheckStatus;
  final VoidCallback onCancel;

  const _KHQRPaymentDialog({
    required this.qrCode,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.onCheckStatus,
    required this.onCancel,
  });

  @override
  State<_KHQRPaymentDialog> createState() => _KHQRPaymentDialogState();
}

class _KHQRPaymentDialogState extends State<_KHQRPaymentDialog> {
  bool _checking = false;
  Timer? _autoCheckTimer;
  int _checkCount = 0;

  @override
  void initState() {
    super.initState();
    // Start auto-checking payment status every 5 seconds
    _startAutoCheck();
  }

  @override
  void dispose() {
    // Cancel the timer when dialog is closed
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    // Check immediately after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkPaymentStatus();
    });

    // Then check every 5 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_checking) {
        _checkPaymentStatus();
      }

      // Stop after 20 checks (100 seconds / ~1.5 minutes)
      _checkCount++;
      if (_checkCount >= 20) {
        timer.cancel();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_checking) return;

    setState(() => _checking = true);

    try {
      await widget.onCheckStatus();
    } catch (e) {
      // If we get authentication error (401), stop auto-checking
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _autoCheckTimer?.cancel();
        if (mounted) {
          setState(() => _checking = false);
        }
        return;
      }
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code, color: Colors.green),
          const SizedBox(width: 8),
          const Text('KHQR Payment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan QR code to pay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Image.memory(
                _base64ToImage(widget.qrCode),
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount: ${widget.amount} ${widget.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transaction ID: ${widget.transactionId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_checking) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _checking
                      ? 'Checking payment status...'
                      : 'Auto-checking every 5 seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _checking ? Colors.blue : Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _checking ? null : _checkPaymentStatus,
          icon: _checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Check Now'),
        ),
      ],
    );
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      // Remove data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      // Return empty byte array if decode fails
      return Uint8List(0);
    }
  }
}
