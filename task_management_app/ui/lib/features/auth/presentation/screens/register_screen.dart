import 'package:flutter/material.dart';
import '../../../../common/widgets/app_button.dart';
import '../../../../common/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _onRegister() async {
    setState(() => _loading = true);
    // TODO: Wire to AuthApi.register
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(controller: _name, label: 'Name'),
            const SizedBox(height: 12),
            AppTextField(controller: _email, label: 'Email'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: _loading ? 'Registering...' : 'Register',
              onPressed: _loading ? null : _onRegister,
            ),
          ],
        ),
      ),
    );
  }
}
