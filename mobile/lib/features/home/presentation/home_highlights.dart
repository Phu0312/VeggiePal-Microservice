import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../recipe/data/recipe_models.dart';
import '../../recipe/data/recipe_repository.dart';
import '../../recipe/presentation/recipe_detail_screen.dart';
import '../../recipe/presentation/recipes_screen.dart';
import '../data/recommendation_controller.dart';
import '../data/recommendation_repository.dart';
import 'blog_detail_screen.dart';

/// Hai khối nổi bật ở đầu Trang chủ (giống trang chủ bản web):
///  - "Món chay mới": các công thức vừa đăng (GET /recipes?size=6; backend chưa có xếp hạng được yêu thích).
///  - "Gợi ý dành riêng cho bạn": AI chọn bài viết và công thức kèm lý do (GET /ai/recommendations, cần đăng nhập);
///    khách thấy lời mời đăng nhập.
/// Lỗi của từng khối hiện ngay trong khối đó kèm nút "Thử lại" (không bật popup) để không che bảng tin bên dưới.
/// `reload()` qua GlobalKey tải lại cả hai khối (kéo để làm mới ở Trang chủ).
class HomeHighlights extends StatefulWidget {
  const HomeHighlights({super.key});

  @override
  State<HomeHighlights> createState() => HomeHighlightsState();
}

class HomeHighlightsState extends State<HomeHighlights> {
  static const _tileHeight = 236.0;

  List<Recipe> _recipes = [];
  bool _loadingRecipes = true;
  String? _recipesError;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  /// Tải lại công thức mới và (nếu đã đăng nhập) gợi ý của AI.
  Future<void> reload() async {
    final recs = context.read<RecommendationController>();
    await Future.wait([_loadRecipes(), if (context.read<AuthController>().isLoggedIn) recs.refresh()]);
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _loadingRecipes = true;
      _recipesError = null;
    });
    try {
      final page = await context.read<RecipeRepository>().published(size: 6);
      if (mounted) setState(() => _recipes = page.items);
    } catch (e) {
      if (mounted) setState(() => _recipesError = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingRecipes = false);
    }
  }

  Future<void> _login() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _openRecommendation(Recommendation r) {
    final route = r.isRecipe
        ? MaterialPageRoute<void>(
            builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r.toRecipe()))
        : MaterialPageRoute<void>(builder: (_) => BlogDetailScreen(summary: r.toBlog()));
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final recs = context.watch<RecommendationController>();
    if (auth.isLoggedIn) {
      // Chỉ gọi AI khi chưa có kết quả hoặc đã cũ (xem RecommendationController.ensureLoaded).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) recs.ensureLoaded();
      });
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        'Món chay mới',
        trailing: TextButton(
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecipesScreen())),
          child: const Text('Xem tất cả'),
        ),
      ),
      _recipeStrip(),
      SectionHeader(
        'Gợi ý dành riêng cho bạn',
        trailing: auth.isLoggedIn
            ? IconButton(
                tooltip: 'Gợi ý mới',
                onPressed: recs.loading ? null : recs.refresh,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
              )
            : null,
      ),
      if (!auth.isLoggedIn) _guestPrompt() else _recommendations(recs),
      const SectionHeader('Bảng tin cộng đồng'),
    ]);
  }

  // ---------------- Món chay mới ----------------

  Widget _recipeStrip() {
    if (_loadingRecipes && _recipes.isEmpty) return const _StripLoading();
    if (_recipesError != null && _recipes.isEmpty) {
      return _StripMessage(_recipesError!, onRetry: _loadRecipes);
    }
    if (_recipes.isEmpty) return const _StripMessage('Chưa có công thức nào được đăng.');
    return SizedBox(
      height: _tileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recipes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = _recipes[i];
          final n = r.nutrition;
          return _HighlightCard(
            imageUrl: r.imageUrl,
            badge: null,
            title: r.title,
            subtitle: [
              if (r.totalMinutes != null && r.totalMinutes! > 0) '${r.totalMinutes} phút',
              '${r.servings} khẩu phần',
              if (n != null) '${n.kcal} kcal',
            ].join(' • '),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r))),
          );
        },
      ),
    );
  }

  // ---------------- Gợi ý của AI ----------------

  Widget _guestPrompt() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(LucideIcons.sparkles, color: context.cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Đăng nhập để AI chọn công thức và bài viết chay hợp khẩu vị của bạn.',
                    style: TextStyle(color: context.textMuted)),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _login, child: const Text('Đăng nhập')),
            ]),
          ),
        ),
      );

  Widget _recommendations(RecommendationController recs) {
    if (recs.loading && recs.items.isEmpty) {
      return const _StripLoading(label: 'AI đang chọn nội dung cho bạn...');
    }
    if (recs.error != null && recs.items.isEmpty) {
      return _StripMessage(recs.error!, onRetry: recs.refresh);
    }
    if (recs.items.isEmpty) {
      return const _StripMessage('Chưa có gợi ý phù hợp lúc này. Hãy thử lại sau khi có thêm công thức và bài viết.');
    }
    return SizedBox(
      height: 292,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recs.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = recs.items[i];
          return _HighlightCard(
            imageUrl: r.imageUrl,
            badge: r.typeLabel,
            title: r.title,
            subtitle: r.reason,
            subtitleLines: 3,
            onTap: () => _openRecommendation(r),
          );
        },
      ),
    );
  }
}

/// Thẻ nằm ngang trong dải cuộn: ảnh, nhãn loại (tuỳ chọn), tên và một dòng phụ.
class _HighlightCard extends StatelessWidget {
  final String? imageUrl;
  final String? badge;
  final String title;
  final String subtitle;
  final int subtitleLines;
  final VoidCallback onTap;
  const _HighlightCard({
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.subtitle,
    this.subtitleLines = 2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              VegImage(imageUrl, width: 220, height: 120),
              if (badge != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: context.cs.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge!,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.cs.onPrimary)),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: subtitleLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StripLoading extends StatelessWidget {
  final String? label;
  const _StripLoading({this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (label != null) ...[const SizedBox(width: 10), Text(label!, style: TextStyle(color: context.textMuted))],
        ]),
      );
}

class _StripMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _StripMessage(this.message, {this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Text(message, style: TextStyle(color: context.textMuted))),
              if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ]),
          ),
        ),
      );
}
