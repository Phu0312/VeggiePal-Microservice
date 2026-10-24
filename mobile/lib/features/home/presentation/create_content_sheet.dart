import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../blog/data/blog_models.dart';
import '../../notifications/notification_controller.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Bottom sheet đăng Bài viết hoặc Video (chỉ mở cho thành viên đã đăng nhập).
/// Trả về true nếu đăng/lưu thành công để màn Home tải lại.
/// Bài viết: kiểm tra trước khi gửi theo luật của BE (tiêu đề ≤ 150, nội dung ≥ 20 ký tự, bắt buộc
/// chọn danh mục), có thể "Đăng bài" hoặc "Lưu nháp". Muốn thêm ảnh bìa/sửa sau: Hồ sơ > Bài viết của tôi.
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
  final _form = GlobalKey<FormState>();
  bool _isVideo = false;
  int? _categoryId;
  final _title = TextEditingController();
  final _body = TextEditingController(); // nội dung blog hoặc URL video
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool publish}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<HomeRepository>();
    final notifications = context.read<NotificationController>();
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    try {
      if (_isVideo) {
        await repo.createVideo(_title.text.trim(), _body.text.trim(), null, _categoryId);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Đã gửi video.')));
        return;
      }
      final blog = await repo.createBlog(_title.text.trim(), _body.text.trim(), _categoryId!,
          publish: publish);
      notifications.refresh();
      if (!mounted) return;
      final out = blogOutcome(blog);
      Navigator.of(context).pop(true);
      // Thông báo đúng theo trạng thái BE trả về (đã đăng / chờ duyệt / bị từ chối / nháp).
      if (out.needsDialog && rootContext.mounted) {
        showInfoDialog(rootContext, out.title, out.message);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(out.message)));
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
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FullWidthSegmented<bool>(
            options: const [
              SegmentOption(false, 'Bài viết', icon: LucideIcons.fileText),
              SegmentOption(true, 'Video', icon: LucideIcons.video),
            ],
            selected: _isVideo,
            onChanged: (v) => setState(() => _isVideo = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _title,
            maxLength: 150,
            decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề (tối đa 150 ký tự)',
                prefixIcon: Icon(LucideIcons.type)),
            validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _body,
            maxLines: _isVideo ? 1 : 5,
            decoration: InputDecoration(
              labelText: _isVideo ? 'Đường dẫn video (URL)' : 'Nội dung',
              hintText: _isVideo ? 'Dán đường dẫn video' : 'Nhập nội dung (tối thiểu 20 ký tự)',
              prefixIcon: Icon(_isVideo ? LucideIcons.link : LucideIcons.fileText),
            ),
            validator: (v) {
              final t = v!.trim();
              if (t.isEmpty) return _isVideo ? 'Vui lòng nhập đường dẫn video' : 'Vui lòng nhập nội dung';
              if (!_isVideo && t.length < 20) return 'Nội dung tối thiểu 20 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Danh mục', prefixIcon: Icon(LucideIcons.tag)),
            items: [
              for (final c in widget.cats) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
            // Bài viết bắt buộc có danh mục (BE), video thì không.
            validator: (v) => !_isVideo && v == null ? 'Vui lòng chọn danh mục' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _busy ? null : () => _submit(publish: true),
                child: Text(_isVideo ? 'Đăng video' : 'Đăng bài')),
          ),
          if (!_isVideo) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: _busy ? null : () => _submit(publish: false),
                  child: const Text('Lưu nháp')),
            ),
          ],
        ]),
      ),
    );
  }
}
