import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import 'auth_controller.dart';

/// Màn hình Đăng nhập / Đăng ký (chuyển đổi bằng một nút).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'user@veggiepal.com');
  final _password = TextEditingController(text: 'Demo@123');
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _register = false;
  bool _busy = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    try {
      if (_register) {
        await auth.register(_email.text, _password.text, _name.text, _phone.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Đăng ký' : 'Đăng nhập')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const AppLogo(size: 96),
              const SizedBox(height: 16),
              if (_register) ...[
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Họ tên'),
                    validator: (v) => v!.trim().isEmpty ? 'Nhập họ tên' : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại')),
                const SizedBox(height: 12),
              ],
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ'),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (v) => v!.length < 6 ? 'Tối thiểu 6 ký tự' : null),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_register ? 'Tạo tài khoản' : 'Đăng nhập'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(_register
                    ? 'Đã có tài khoản? Đăng nhập'
                    : 'Chưa có tài khoản? Đăng ký'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
