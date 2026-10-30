import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import 'auth_controller.dart';
import 'otp_widgets.dart';

/// Xác minh email bằng mã 6 số (POST /auth/verify-email). Pop `true` khi email đã được xác minh.
/// - Sau khi đăng ký: BE đã tự gửi mã nên màn hình chỉ chờ nhập ([sendOnOpen] = false).
/// - Mở từ Hồ sơ: màn hình tự gửi mã mới khi mở ([sendOnOpen] = true, POST /auth/send-verification).
/// Chưa xác minh vẫn dùng app bình thường nên có nút "Để sau".
class VerifyEmailScreen extends StatefulWidget {
  final bool sendOnOpen;
  const VerifyEmailScreen({super.key, this.sendOnOpen = false});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _resendKey = GlobalKey<ResendCodeButtonState>();
  final _otp = TextEditingController();
  bool _busy = false;
  int _expiresInSeconds = 300;

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen) WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  /// Gửi mã tới email của tài khoản. Trả `true` nếu BE đã gửi.
  Future<bool> _send() async {
    final auth = context.read<AuthController>();
    setState(() => _busy = true);
    try {
      final sent = await auth.sendVerification();
      _expiresInSeconds = sent.expiresInSeconds;
      if (mounted) {
        _resendKey.currentState?.restart();
        showSnack(context, 'Đã gửi mã tới ${auth.user?.email ?? 'email của bạn'}');
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (e is ApiException && e.code == 1028) {
        // Email đã xác minh ở nơi khác (web, thiết bị khác): đồng bộ lại rồi thoát.
        auth.updateUser(emailVerified: true);
        Navigator.of(context).pop(true);
        return false;
      }
      setState(() => _busy = false);
      await showErrorDialog(context, errorMessage(e), title: 'Không gửi được mã');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await auth.verifyEmail(_otp.text);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Đã xác minh email')));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        await showErrorDialog(context, errorMessage(e), title: 'Xác minh không thành công');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthController>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const AppLogo(size: 80),
              const SizedBox(height: 16),
              Text(
                  'Mã gồm 6 chữ số đã được gửi tới $email. '
                  'Mã có hiệu lực trong ${(_expiresInSeconds / 60).ceil()} phút.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textMuted)),
              const SizedBox(height: 16),
              OtpField(controller: _otp, onSubmitted: _busy ? null : _verify),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _verify,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Xác minh'),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: const Text('Để sau')),
                ResendCodeButton(
                    key: _resendKey, onResend: _send, initialCooldown: widget.sendOnOpen ? 0 : 60),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
