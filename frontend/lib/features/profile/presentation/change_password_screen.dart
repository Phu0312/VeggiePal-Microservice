import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/profile_repository.dart';

/// Đổi mật khẩu: PUT /users/me/password {currentPassword, newPassword}.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<ProfileRepository>().changePassword(_current.text, _next.text);
      if (!mounted) return;
      showSnack(context, 'Đã đổi mật khẩu thành công');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không đổi được mật khẩu');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label, String hint, IconData icon) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          tooltip: _show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
          icon: Icon(_show ? LucideIcons.eyeOff : LucideIcons.eye),
          onPressed: () => setState(() => _show = !_show),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(children: [
            TextFormField(
              controller: _current,
              obscureText: !_show,
              decoration: _dec('Mật khẩu hiện tại', 'Nhập mật khẩu đang dùng', LucideIcons.lock),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu hiện tại' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: !_show,
              decoration: _dec('Mật khẩu mới', 'Tối thiểu 6 ký tự', LucideIcons.keyRound),
              validator: (v) {
                if (v!.length < 6) return 'Mật khẩu mới tối thiểu 6 ký tự';
                if (v == _current.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: !_show,
              decoration: _dec('Xác nhận mật khẩu mới', 'Nhập lại mật khẩu mới', LucideIcons.shieldCheck),
              validator: (v) => v != _next.text ? 'Mật khẩu xác nhận không khớp' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Đổi mật khẩu'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
