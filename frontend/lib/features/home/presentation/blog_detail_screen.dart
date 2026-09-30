import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Chi tiết bài viết: hiển thị ngay dữ liệu tóm tắt, sau đó nạp nội dung đầy đủ từ GET /blogs/{id}.
class BlogDetailScreen extends StatelessWidget {
  final BlogItem summary;
  const BlogDetailScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: FutureBuilder<BlogItem>(
        future: context.read<HomeRepository>().blogDetail(summary),
        builder: (context, snap) {
          final b = snap.data ?? summary;
          return ListView(
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
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else
                Text(b.content ?? '', style: const TextStyle(height: 1.5, fontSize: 16)),
            ],
          );
        },
      ),
    );
  }
}
