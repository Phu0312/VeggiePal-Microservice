import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/auth_validators.dart';
import '../data/google_auth.dart';
import 'auth_controller.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

/// Màn hình Đăng nhập / Đăng ký (chuyển đổi bằng một nút) và "Tiếp tục với Google".
/// - Đăng nhập: email + mật khẩu (POST /auth/login). Tick "Ghi nhớ đăng nhập" thì phiên được lưu lại,
///   lần mở app sau không phải đăng nhập lại.
/// - Đăng ký: họ tên, số điện thoại (không bắt buộc), email, mật khẩu (tối thiểu 6 ký tự) và nhập lại mật khẩu
///   (POST /auth/register) rồi tự đăng nhập và mở màn xác minh email (BE đã gửi mã 6 số tới email đó).
/// - "Quên mật khẩu?": mở [ForgotPasswordScreen]; đặt lại xong thì điền sẵn email để đăng nhập.
/// - Google: lấy ID token từ Google rồi gửi POST /auth/google; backend tạo tài khoản mới nếu email chưa có.
///   Luồng này luôn ghi nhớ đăng nhập.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _googleBusy = false;
  bool _showPassword = false;
  bool _remember = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
        await auth.register(_email.text.trim(), _password.text, _name.text.trim(), _phone.text.trim(),
            remember: _remember);
      } else {
        await auth.login(_email.text, _password.text, remember: _remember);
      }
      if (!mounted) return;
      if (_register) {
        // Thay chính màn này để đóng màn xác minh là quay về nơi đã mở đăng nhập.
        await Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Ngừng vòng quay trước khi hiện popup, nếu không nó quay mãi sau lưng popup.
        setState(() => _busy = false);
        await showErrorDialog(context, errorMessage(e),
            title: _register ? 'Đăng ký thất bại' : 'Đăng nhập thất bại');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleBusy = true);
    final auth = context.read<AuthController>();
    final google = context.read<GoogleIdTokenSource>();
    try {
      final token = await google.idToken();
      if (token == null) return; // người dùng tự đóng màn chọn tài khoản
      await auth.loginWithGoogle(token);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _googleBusy = false);
        await showErrorDialog(context, errorMessage(e), title: 'Đăng nhập bằng Google thất bại');
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())));
    if (email == null || !mounted) return;
    setState(() {
      _email.text = email;
      _password.clear();
    });
    showSnack(context, 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.');
  }

  void _toggleMode() => setState(() => _register = !_register);

  @override
  Widget build(BuildContext context) {
    final busy = _busy || _googleBusy;
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
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Họ tên',
                        hintText: 'Nhập họ và tên của bạn',
                        prefixIcon: Icon(LucideIcons.user)),
                    validator: validateFullName),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Số điện thoại (không bắt buộc)',
                        hintText: 'Nhập số điện thoại',
                        prefixIcon: Icon(LucideIcons.phone)),
                    validator: validatePhone),
                const SizedBox(height: 12),
              ],
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập địa chỉ email',
                      prefixIcon: Icon(LucideIcons.mail)),
                  validator: validateEmail),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  textInputAction: _register ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: (_) => (_register || busy) ? null : _submit(),
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
                  validator: validatePassword),
              if (_register) ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _confirm,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                    decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                        hintText: 'Nhập lại mật khẩu ở trên',
                        prefixIcon: Icon(LucideIcons.lockKeyhole)),
                    validator: (v) => validateConfirmPassword(v, _password.text)),
              ],
              if (!_register)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: busy ? null : _forgotPassword, child: const Text('Quên mật khẩu?')),
                ),
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
                  onPressed: busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_register ? 'Tạo tài khoản' : 'Đăng nhập'),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('hoặc', style: TextStyle(color: context.textMuted)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _google,
                  icon: _googleBusy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const _GoogleMark(),
                  label: const Text('Tiếp tục với Google'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : _toggleMode,
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

/// Chữ "G" nhiều màu thay cho logo Google (không kèm tệp ảnh).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text('G',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4)));
}
