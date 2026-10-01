import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Chi tiết bài viết: hiển thị ngay dữ liệu tóm tắt, sau đó nạp nội dung đầy đủ từ GET /blogs/{id}.
/// Nếu không lấy được nội dung thì hiện popup lỗi.
class BlogDetailScreen extends StatefulWidget {
  final BlogItem summary;
  const BlogDetailScreen({super.key, required this.summary});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogItem? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<HomeRepository>().blogDetail(widget.summary);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được bài viết');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _detail ?? widget.summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VegImage(b.thumbnailUrl, height: 200, width: double.infinity),
          const SizedBox(height: 16),
          Text(b.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${b.categoryName ?? ''}  •  ${b.viewCount} lượt xem'),
          const Divider(height: 32),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_detail == null)
            Center(
                child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại')))
          else
            Text(b.content ?? '', style: const TextStyle(height: 1.5, fontSize: 16)),
        ],
      ),
    );
  }
}
