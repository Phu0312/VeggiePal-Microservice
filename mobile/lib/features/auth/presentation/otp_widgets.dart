import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/auth_validators.dart';

/// Ô nhập mã OTP 6 chữ số (quên mật khẩu, xác minh email).
class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  const OtpField({super.key, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
        onFieldSubmitted: (_) => onSubmitted?.call(),
        decoration: const InputDecoration(
            labelText: 'Mã xác nhận', hintText: '------', prefixIcon: Icon(LucideIcons.shieldCheck)),
        validator: validateOtp,
      );
}

/// Nút "Gửi lại mã" có đếm ngược, tránh bấm liên tục. [onResend] trả `true` khi đã gửi được thì đếm ngược bắt đầu lại.
class ResendCodeButton extends StatefulWidget {
  final Future<bool> Function() onResend;

  /// Số giây phải chờ ngay khi mở màn hình (0 = cho gửi ngay).
  final int initialCooldown;
  final int cooldown;
  const ResendCodeButton({super.key, required this.onResend, this.initialCooldown = 60, this.cooldown = 60});

  @override
  State<ResendCodeButton> createState() => ResendCodeButtonState();
}

class ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  late int _left = widget.initialCooldown;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_left > 0) _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Bắt đầu đếm ngược lại (màn hình cha gọi sau khi tự gửi mã).
  void restart() {
    _left = widget.cooldown;
    _tick();
    setState(() {});
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _press() async {
    setState(() => _busy = true);
    try {
      if (await widget.onResend() && mounted) restart();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: (_left > 0 || _busy) ? null : _press,
        child: Text(_left > 0 ? 'Gửi lại mã sau ${_left}s' : 'Gửi lại mã'),
      );
}
