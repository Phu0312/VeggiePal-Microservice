import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';

/// Logo VeggiePal dạng biểu tượng (SVG trong assets/icons/logo_mark.svg, không chữ/không nền).
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/icons/logo_mark.svg', width: size, height: size);
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
      child: const Icon(Icons.eco, color: AppColors.primary),
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
          backgroundColor: WidgetStateProperty.all(Colors.white),
          leading: const Icon(Icons.search),
          onSubmitted: onSubmitted,
        ),
      );
}

void showSnack(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

/// Ảnh Unsplash chủ đề vegan dùng cho Mock Data.
const mockImages = [
  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
  'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600',
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600',
  'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600',
  'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600',
  'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=600',
  'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=600',
];
String mockImage(int i) => mockImages[i.abs() % mockImages.length];
