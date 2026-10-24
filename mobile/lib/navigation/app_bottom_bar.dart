import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';

/// 5 mục điều hướng; mục ở giữa ([centerIndex]) là nút tròn nổi (Trợ lý AI).
class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

const navItems = [
  NavItem(LucideIcons.house, 'Trang chủ'),
  NavItem(LucideIcons.store, 'Quán chay'),
  NavItem(LucideIcons.sparkles, 'Trợ lý AI'),
  NavItem(LucideIcons.calendarDays, 'Thực đơn'),
  NavItem(LucideIcons.user, 'Hồ sơ'),
];
const centerIndex = 2;

/// Thanh điều hướng dưới: mục đang chọn có gạch nhỏ phía trên + chữ đậm,
/// riêng mục giữa là nút tròn nổi lên khỏi thanh (đặt bằng [AiFabLocation]).
class AppBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const AppBottomBar({super.key, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      elevation: 8,
      shadowColor: Colors.black38,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < navItems.length; i++)
                Expanded(
                  child: i == centerIndex
                      ? _CenterLabel(
                          navItems[i].label,
                          selected: index == i,
                          onTap: () => onSelect(i),
                        )
                      : _BarItem(
                          navItems[i],
                          selected: index == i,
                          onTap: () => onSelect(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _BarItem(this.item, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = selected ? cs.onSurface : context.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          // Gạch chỉ báo mục đang chọn.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: selected ? 36 : 0,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(3),
              ),
            ),
          ),
          const Spacer(),
          Icon(item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Phần nhãn của mục giữa (nút tròn nằm phía trên, do FAB vẽ).
class _CenterLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CenterLabel(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11.5,
            color: selected ? context.cs.onSurface : context.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

/// Nút tròn Trợ lý AI ở giữa, nổi lên khỏi thanh điều hướng.
class AiFab extends StatelessWidget {
  final VoidCallback onPressed;
  const AiFab({super.key, required this.onPressed});

  static const size = 60.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FloatingActionButton(
      heroTag: 'ai-fab',
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: const Icon(LucideIcons.sparkles, size: 28),
    ),
  );
}

/// Đặt FAB giữa màn hình, phần trên nằm phía trên thanh điều hướng (giống ảnh mẫu).
class AiFabLocation extends FloatingActionButtonLocation {
  const AiFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    final x = (g.scaffoldSize.width - g.floatingActionButtonSize.width) / 2;
    // contentBottom = mép trên của thanh điều hướng; chỉ nhô ~1/3 nút lên trên thanh.
    final y = g.contentBottom - 20;
    return Offset(x, y);
  }
}
