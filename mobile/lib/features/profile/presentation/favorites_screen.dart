import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/data/home_models.dart';
import '../../home/presentation/blog_detail_screen.dart';
import '../../recipe/presentation/recipe_detail_screen.dart';
import '../../video/presentation/video_watch_screen.dart';
import '../data/favorites_controller.dart';
import '../data/profile_models.dart';

/// Mục đã lưu (GET /users/me/favorites) chia theo ba tab: công thức, bài viết, video.
/// Chạm để mở nội dung đầy đủ, nút thùng rác để bỏ khỏi danh sách. Kéo xuống để tải lại.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FavoritesController>().refresh());
  }

  void _open(FavoriteItem i) {
    final page = switch (i.type) {
      FavoriteType.recipe => RecipeDetailScreen(recipeId: i.targetId),
      FavoriteType.blog => BlogDetailScreen(summary: BlogItem(id: i.targetId, title: i.title, thumbnailUrl: i.imageUrl)),
      FavoriteType.video => VideoWatchScreen(videoId: i.targetId),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _remove(FavoriteItem i) async {
    final error = await context.read<FavoritesController>().remove(i);
    if (!mounted) return;
    if (error != null) {
      showErrorDialog(context, error, title: 'Không bỏ được khỏi yêu thích');
    } else {
      showSnack(context, 'Đã bỏ "${i.title}" khỏi yêu thích');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    return DefaultTabController(
      length: FavoriteType.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu thích'),
          bottom: TabBar(tabs: [for (final t in FavoriteType.values) Tab(text: '${t.label} (${favorites.ofType(t).length})')]),
        ),
        body: !favorites.loaded
            ? (favorites.loading
                ? const Center(child: CircularProgressIndicator())
                : RetryView(message: favorites.error ?? 'Không tải được danh sách.', onRetry: favorites.refresh))
            : TabBarView(children: [
                for (final t in FavoriteType.values)
                  RefreshIndicator(
                    onRefresh: favorites.refresh,
                    child: favorites.ofType(t).isEmpty
                        ? ListView(children: [
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Text(
                                  'Chưa lưu ${t.label.toLowerCase()} nào.\nBấm biểu tượng đánh dấu ở thanh tiêu đề để lưu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: context.textMuted)),
                            ),
                          ])
                        : ListView(padding: const EdgeInsets.all(16), children: [
                            for (final i in favorites.ofType(t))
                              Card(
                                child: ListTile(
                                  onTap: () => _open(i),
                                  leading: VegImage(i.imageUrl, width: 56, height: 56, radius: BorderRadius.circular(10)),
                                  title: Text(i.title.isEmpty ? '${t.label} #${i.targetId}' : i.title,
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    tooltip: 'Bỏ khỏi yêu thích',
                                    icon: const Icon(LucideIcons.trash2),
                                    onPressed: () => _remove(i),
                                  ),
                                ),
                              ),
                          ]),
                  ),
              ]),
      ),
    );
  }
}
