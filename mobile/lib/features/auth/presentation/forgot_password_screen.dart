import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/auth_repository.dart';
import '../data/auth_validators.dart';
import 'otp_widgets.dart';

enum _Step { email, code, password }

/// Quên mật khẩu, ba bước trên một màn hình:
/// 1. Nhập email -> POST /auth/forgot-password, BE gửi mã 6 số (luôn báo thành công, kể cả khi email chưa đăng ký
///    hoặc đã quá 3 mã/giờ cho email đó; quá 10 lần/giờ từ một IP thì trả 429, mã 1033; chưa cấu hình SMTP thì 503, mã 1034).
/// 2. Nhập mã -> POST /auth/verify-otp, BE trả `resetToken` dùng một lần.
/// 3. Nhập mật khẩu mới -> POST /auth/reset-password; BE thu hồi mọi phiên đăng nhập cũ.
/// Đặt lại thành công thì màn hình đóng và trả về email để màn đăng nhập điền sẵn.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _resendKey = GlobalKey<ResendCodeButtonState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Step _step = _Step.email;
  bool _busy = false;
  bool _showPassword = false;
  String _resetToken = '';
  int _expiresInSeconds = 300;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  AuthRepository get _repo => context.read<AuthRepository>();

  /// Chạy một bước gọi BE: bật vòng quay, báo lỗi bằng popup. [onError] cho phép quay về bước trước với một số mã lỗi.
  Future<bool> _run(Future<void> Function() call, String errorTitle, {void Function(ApiException)? onError}) async {
    setState(() => _busy = true);
    try {
      await call();
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        if (e is ApiException) onError?.call(e);
        await showErrorDialog(context, errorMessage(e), title: errorTitle);
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    final ok = await _run(() async {
      final sent = await _repo.forgotPassword(_email.text);
      _expiresInSeconds = sent.expiresInSeconds;
    }, 'Không gửi được mã');
    if (ok && mounted) {
      setState(() {
        _otp.clear();
        _step = _Step.code;
      });
    }
  }

  Future<bool> _resend() async {
    final ok = await _run(() async {
      final sent = await _repo.forgotPassword(_email.text);
      _expiresInSeconds = sent.expiresInSeconds;
    }, 'Không gửi được mã');
    if (ok && mounted) showSnack(context, 'Đã gửi yêu cầu gửi lại mã. Nếu email đã đăng ký, mã mới sẽ đến trong ít phút.');
    return ok;
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final ok = await _run(() async {
      _resetToken = await _repo.verifyResetOtp(_email.text, _otp.text);
    }, 'Mã không hợp lệ', onError: (e) {
      // Nhập sai quá số lần cho phép: mã cũ bị khóa, phải xin mã mới.
      if (e.code == 1026) setState(() => _step = _Step.email);
    });
    if (ok && mounted) setState(() => _step = _Step.password);
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    final ok = await _run(() => _repo.resetPassword(_resetToken, _password.text), 'Không đặt lại được mật khẩu',
        onError: (e) {
      if (e.code == 1027) setState(() => _step = _Step.email); // phiên đặt lại hết hạn
    });
    if (ok && mounted) Navigator.of(context).pop(_email.text.trim());
  }

  String get _title => switch (_step) {
        _Step.email => 'Quên mật khẩu',
        _Step.code => 'Nhập mã xác nhận',
        _Step.password => 'Đặt mật khẩu mới',
      };

  List<Widget> _fields() {
    switch (_step) {
      case _Step.email:
        return [
          Text('Nhập email đã đăng ký, chúng tôi sẽ gửi mã xác nhận gồm 6 chữ số.',
              textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _busy ? null : _sendCode(),
              decoration: const InputDecoration(
                  labelText: 'Email', hintText: 'Nhập địa chỉ email', prefixIcon: Icon(LucideIcons.mail)),
              validator: validateEmail),
          const SizedBox(height: 16),
          _primary('Gửi mã', _sendCode),
        ];
      case _Step.code:
        return [
          Text(
              'Nếu ${_email.text.trim()} đã đăng ký, mã gồm 6 chữ số đã được gửi tới đó. '
              'Mã có hiệu lực trong ${(_expiresInSeconds / 60).ceil()} phút. '
              'Mỗi email nhận tối đa 3 mã mỗi giờ, nếu chưa thấy hãy kiểm tra cả thư rác.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          OtpField(controller: _otp, onSubmitted: _busy ? null : _verify),
          const SizedBox(height: 16),
          _primary('Xác nhận', _verify),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: _busy ? null : () => setState(() => _step = _Step.email),
                child: const Text('Đổi email')),
            ResendCodeButton(key: _resendKey, onResend: _resend),
          ]),
        ];
      case _Step.password:
        return [
          Text('Đặt mật khẩu mới cho ${_email.text.trim()}. Các thiết bị đang đăng nhập sẽ bị đăng xuất.',
              textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: validatePassword),
          const SizedBox(height: 12),
          TextFormField(
              controller: _confirm,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _busy ? null : _reset(),
              decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                  hintText: 'Nhập lại mật khẩu ở trên',
                  prefixIcon: Icon(LucideIcons.lockKeyhole)),
              validator: (v) => validateConfirmPassword(v, _password.text)),
          const SizedBox(height: 16),
          _primary('Đặt lại mật khẩu', _reset),
        ];
    }
  }

  Widget _primary(String label, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : onPressed,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const AppLogo(size: 80),
                const SizedBox(height: 16),
                ..._fields(),
              ]),
            ),
          ),
        ),
      );
}
