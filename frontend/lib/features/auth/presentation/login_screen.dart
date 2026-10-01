import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import 'auth_controller.dart';

/// Màn hình Đăng nhập / Đăng ký (chuyển đổi bằng một nút).
/// Tick "Ghi nhớ đăng nhập" thì phiên được lưu lại, lần mở app sau không phải đăng nhập lại.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  bool _remember = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    try {
      if (_register) {
        await auth.register(_email.text, _password.text, _name.text, _phone.text,
            remember: _remember);
      } else {
        await auth.login(_email.text, _password.text, remember: _remember);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, errorMessage(e),
            title: _register ? 'Đăng ký thất bại' : 'Đăng nhập thất bại');
      }
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
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Họ tên',
                        hintText: 'Nhập họ và tên của bạn',
                        prefixIcon: Icon(LucideIcons.user)),
                    validator: (v) => v!.trim().isEmpty ? 'Nhập họ tên' : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: 'Nhập số điện thoại',
                        prefixIcon: Icon(LucideIcons.phone))),
                const SizedBox(height: 12),
              ],
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập địa chỉ email',
                      prefixIcon: Icon(LucideIcons.mail)),
                  validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ'),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  onFieldSubmitted: (_) => _busy ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                    prefixIcon: const Icon(LucideIcons.lock),
                    suffixIcon: IconButton(
                      tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                      icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Tối thiểu 6 ký tự' : null),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                title: const Text('Ghi nhớ đăng nhập'),
                subtitle: const Text('Không cần đăng nhập lại khi mở app'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 12),
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
