import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../../../common/widgets/app_button.dart';
import '../../../../common/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _onLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(authProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (ok && mounted) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
    } catch (e) {
      setState(() => _error = 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            AppTextField(controller: _email, label: 'Email'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: _loading ? 'Logging in...' : 'Login',
              icon: Icons.login,
              onPressed: _loading ? null : _onLogin,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.register),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
