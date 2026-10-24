import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/data/home_models.dart';
import '../../home/data/home_repository.dart';
import '../data/blog_models.dart';
import '../data/blog_repository.dart';

/// Viết bài mới hoặc sửa bài của tôi.
/// - Tạo: POST /blogs (publish=false lưu nháp, publish=true kiểm duyệt ngay), rồi POST /blogs/{id}/thumbnail.
/// - Sửa: PUT /blogs/{id} (bài đã qua kiểm duyệt sẽ bị kiểm duyệt lại); bản nháp có thêm "Lưu và gửi duyệt"
///   (POST /blogs/{id}/submit).
/// Giới hạn của BE: chỉ GET /blogs/{id} của bài đã ĐĂNG mới trả nội dung, nên với bài chưa đăng
/// (nháp, chờ duyệt, bị từ chối) người dùng phải nhập lại nội dung khi sửa.
class BlogEditorScreen extends StatefulWidget {
  final BlogItem? existing; // null = viết bài mới
  const BlogEditorScreen({super.key, this.existing});

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  final _content = TextEditingController();
  List<CategoryItem> _cats = [];
  int? _categoryId;
  Uint8List? _pickedImage; // ảnh bìa mới chọn (chưa tải lên)
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;
  String? get _status => widget.existing?.status;
  bool get _contentAvailable => !_isEdit || _status == 'PUBLISHED';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final home = context.read<HomeRepository>();
      final cats = await home.categories();
      BlogItem? full;
      if (_isEdit && _status == 'PUBLISHED') full = await home.blogDetail(widget.existing!);
      if (!mounted) return;
      setState(() {
        _cats = cats;
        final cid = full?.categoryId ?? widget.existing?.categoryId;
        _categoryId = cats.any((c) => c.id == cid) ? cid : null;
        if (full != null) _content.text = full.content ?? '';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được dữ liệu');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final f = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (mounted) setState(() => _pickedImage = bytes);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không chọn được ảnh');
    }
  }

  /// [publish]: tạo mới -> đăng luôn; sửa bản nháp -> gửi duyệt sau khi lưu.
  Future<void> _save({required bool publish}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final home = context.read<HomeRepository>();
    final blogs = context.read<BlogRepository>();
    // Lấy sẵn messenger/context gốc trước các lệnh await để thông báo vẫn hiện trên danh sách sau khi đóng màn hình.
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final title = _title.text.trim();
    final content = _content.text.trim();
    try {
      BlogItem result;
      if (!_isEdit) {
        result = await home.createBlog(title, content, _categoryId!, publish: publish);
      } else {
        result = await blogs.updateBlog(widget.existing!.id,
            title: title, content: content, categoryId: _categoryId!);
        if (publish && _status == 'DRAFT') result = await blogs.submitBlog(widget.existing!.id);
      }
      String? thumbError;
      if (_pickedImage != null) {
        try {
          // Không gán lại vào result: phản hồi của upload không mang lý do kiểm duyệt.
          await blogs.uploadThumbnail(result.id, _pickedImage!);
        } catch (e) {
          thumbError = errorMessage(e); // bài đã lưu; chỉ ảnh bìa lỗi
        }
      }
      if (!mounted) return;
      final out = blogOutcome(result);
      Navigator.of(context).pop(true);
      if (out.needsDialog && rootContext.mounted) {
        showInfoDialog(rootContext, out.title, out.message);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(out.message)));
      }
      if (thumbError != null && rootContext.mounted) {
        showErrorDialog(rootContext, '$thumbError\nBài viết đã được lưu, bạn có thể đổi ảnh bìa sau.',
            title: 'Không tải được ảnh bìa');
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, errorMessage(e),
            title: _isEdit ? 'Không lưu được bài viết' : 'Không đăng được bài viết');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _cover() {
    final url = widget.existing?.thumbnailUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickImage,
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 170,
            child: _pickedImage != null
                ? Image.memory(_pickedImage!, fit: BoxFit.cover)
                : (url != null && url.isNotEmpty)
                    ? VegImage(url, width: double.infinity, height: 170)
                    : Container(
                        color: context.cs.primaryContainer,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(LucideIcons.imagePlus, size: 36, color: context.cs.onPrimaryContainer),
                          const SizedBox(height: 8),
                          Text('Thêm ảnh bìa (không bắt buộc)',
                              style: TextStyle(color: context.cs.onPrimaryContainer)),
                        ]),
                      ),
          ),
        ),
        if (_pickedImage != null || (url != null && url.isNotEmpty))
          Positioned(
            right: 8,
            bottom: 8,
            child: Chip(
              avatar: const Icon(LucideIcons.camera, size: 16),
              label: const Text('Đổi ảnh bìa'),
              backgroundColor: context.cs.surface,
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftEdit = _isEdit && _status == 'DRAFT';
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa bài viết' : 'Viết bài mới')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RetryView(onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      _cover(),
                      const SizedBox(height: 16),
                      if (_isEdit && !_contentAvailable)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: context.cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(LucideIcons.info, size: 18, color: context.cs.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Bài viết chưa được đăng nên hệ thống không trả lại nội dung cũ. Vui lòng nhập lại nội dung.',
                                  style: TextStyle(fontSize: 13, color: context.cs.onPrimaryContainer)),
                            ),
                          ]),
                        ),
                      TextFormField(
                        controller: _title,
                        textInputAction: TextInputAction.next,
                        maxLength: 150,
                        decoration: const InputDecoration(
                            labelText: 'Tiêu đề',
                            hintText: 'Nhập tiêu đề (tối đa 150 ký tự)',
                            prefixIcon: Icon(LucideIcons.type)),
                        validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Danh mục', prefixIcon: Icon(LucideIcons.tag)),
                        items: [
                          for (final c in _cats) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _content,
                        minLines: 8,
                        maxLines: 20,
                        decoration: const InputDecoration(
                            labelText: 'Nội dung',
                            alignLabelWithHint: true,
                            hintText: 'Chia sẻ công thức, mẹo nấu ăn chay... (tối thiểu 20 ký tự)',
                            prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 140), child: Icon(LucideIcons.fileText))),
                        validator: (v) =>
                            v!.trim().length < 20 ? 'Nội dung tối thiểu 20 ký tự' : null,
                      ),
                      const SizedBox(height: 20),
                      if (!_isEdit) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _save(publish: true),
                            icon: const Icon(LucideIcons.send),
                            label: const Text('Đăng bài'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _save(publish: false),
                            icon: const Icon(LucideIcons.save),
                            label: const Text('Lưu nháp'),
                          ),
                        ),
                      ] else if (draftEdit) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _save(publish: true),
                            icon: const Icon(LucideIcons.send),
                            label: const Text('Lưu và gửi duyệt'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _save(publish: false),
                            icon: const Icon(LucideIcons.save),
                            label: const Text('Lưu nháp'),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _save(publish: false),
                            icon: const Icon(LucideIcons.save),
                            label: const Text('Lưu thay đổi'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Bài viết sẽ được kiểm duyệt lại sau khi sửa.',
                            style: TextStyle(fontSize: 12, color: context.textMuted)),
                      ],
                      if (_busy)
                        const Padding(
                            padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                    ]),
                  ),
                ),
    );
  }
}
