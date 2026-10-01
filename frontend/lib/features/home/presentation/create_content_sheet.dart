import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Bottom sheet đăng Bài viết hoặc Video (chỉ mở cho thành viên đã đăng nhập).
/// Trả về true nếu đăng thành công để màn Home tải lại.
Future<bool?> showCreateContentSheet(BuildContext context, List<CategoryItem> cats) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      // Đẩy nội dung lên trên bàn phím.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _CreateForm(cats),
    ),
  );
}

class _CreateForm extends StatefulWidget {
  final List<CategoryItem> cats;
  const _CreateForm(this.cats);

  @override
  State<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  bool _isVideo = false;
  int? _categoryId;
  final _title = TextEditingController();
  final _body = TextEditingController(); // nội dung blog hoặc URL video
  bool _busy = false;

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      showSnack(context, 'Vui lòng nhập đủ thông tin');
      return;
    }
    setState(() => _busy = true);
    final repo = context.read<HomeRepository>();
    try {
      if (_isVideo) {
        await repo.createVideo(_title.text.trim(), _body.text.trim(), null, _categoryId);
      } else {
        await repo.createBlog(_title.text.trim(), _body.text.trim(), _categoryId);
      }
      if (mounted) {
        showSnack(context, 'Đã gửi! Nội dung sẽ hiển thị sau khi được kiểm duyệt.');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Đăng nội dung thất bại');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Bài viết'), icon: Icon(Icons.article_outlined)),
            ButtonSegment(value: true, label: Text('Video'), icon: Icon(Icons.videocam_outlined)),
          ],
          selected: {_isVideo},
          onSelectionChanged: (s) => setState(() => _isVideo = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Tiêu đề', hintText: 'Nhập tiêu đề', prefixIcon: Icon(LucideIcons.type))),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          maxLines: _isVideo ? 1 : 5,
          decoration: InputDecoration(
            labelText: _isVideo ? 'Đường dẫn video (URL)' : 'Nội dung',
            hintText: _isVideo ? 'Dán đường dẫn video' : 'Nhập nội dung (tối thiểu 20 ký tự)',
            prefixIcon: Icon(_isVideo ? LucideIcons.link : LucideIcons.fileText),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          decoration: const InputDecoration(labelText: 'Danh mục', prefixIcon: Icon(LucideIcons.tag)),
          items: [
            for (final c in widget.cats) DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => _categoryId = v,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: _busy ? null : _submit, child: const Text('Đăng')),
        ),
      ]),
    );
  }
}
