import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Logo VeggiePal (assets/images/logo_app.png). [size] là chiều cao; chiều rộng tự co theo tỉ lệ ảnh.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo_app.png', height: size, fit: BoxFit.contain);
}

/// Ảnh mạng có placeholder + errorBuilder để offline không làm vỡ giao diện.
class VegImage extends StatelessWidget {
  final String? url;
  final double? width, height;
  final BorderRadius? radius;
  const VegImage(this.url, {super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.accent.withValues(alpha: 0.2),
      child: Icon(Icons.eco, color: context.cs.primary),
    );
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(16),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, p) => p == null ? child : placeholder,
              errorBuilder: (_, __, ___) => placeholder),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Ô tìm kiếm dùng chung (SearchBar Material 3).
class VegSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onSubmitted;
  final TextEditingController? controller;
  const VegSearchBar(
      {super.key, required this.hint, required this.onSubmitted, this.controller});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: SearchBar(
          controller: controller,
          hintText: hint,
          elevation: WidgetStateProperty.all(1),
          backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
          leading: const Icon(Icons.search),
          onSubmitted: onSubmitted,
        ),
      );
}

void showSnack(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

final _openErrorDialogs = <String>{};

/// Popup báo lỗi khi không lấy/gửi được dữ liệu từ backend. Cùng một nội dung chỉ hiện một lần
/// tại một thời điểm (nhiều tab tải song song khi backend tắt sẽ không chồng nhiều popup).
Future<void> showErrorDialog(BuildContext context, String message,
    {String title = 'Không thể lấy dữ liệu'}) async {
  if (!context.mounted || !_openErrorDialogs.add(message)) return;
  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 36),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  } finally {
    _openErrorDialogs.remove(message);
  }
}

/// Hiển thị khi không tải được dữ liệu của một màn hình: thông báo ngắn + nút thử lại.
class RetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const RetryView({super.key, this.message = 'Không tải được dữ liệu.', required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ]),
        ),
      );
}
