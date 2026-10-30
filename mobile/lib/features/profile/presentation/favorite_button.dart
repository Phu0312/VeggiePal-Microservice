import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/favorites_controller.dart';
import '../data/profile_models.dart';

/// Nút lưu / bỏ lưu vào danh sách yêu thích ở thanh tiêu đề của công thức, bài viết và video.
/// Khách bấm thì được mời đăng nhập.
class FavoriteButton extends StatefulWidget {
  final FavoriteType type;
  final int targetId;
  final String title;
  final String? imageUrl;
  const FavoriteButton({super.key, required this.type, required this.targetId, required this.title, this.imageUrl});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (!context.read<AuthController>().isLoggedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final favorites = context.read<FavoritesController>();
    final wasFavorite = favorites.isFavorite(widget.type, widget.targetId);
    setState(() => _busy = true);
    final error = await favorites.toggle(widget.type, widget.targetId, title: widget.title, imageUrl: widget.imageUrl);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showErrorDialog(context, error, title: 'Không cập nhật được mục yêu thích');
    } else {
      showSnack(context, wasFavorite ? 'Đã bỏ khỏi yêu thích' : 'Đã lưu vào yêu thích');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<FavoritesController>().isFavorite(widget.type, widget.targetId);
    return IconButton(
      tooltip: saved ? 'Bỏ khỏi yêu thích' : 'Lưu vào yêu thích',
      onPressed: _busy ? null : _toggle,
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}
