import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/data/home_models.dart';
import '../../home/data/home_repository.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';

/// Đăng video mới hoặc sửa video của tôi. Trả về [Video] đã lưu qua Navigator.pop.
/// - Đăng: POST /videos (multipart) với đúng một nguồn là link YouTube hoặc tệp .mp4 (≤ 30MB). "Đăng video" cho
///   backend kiểm duyệt ngay (đăng / chờ duyệt / từ chối); "Lưu nháp" chỉ lưu.
/// - Sửa: PUT /videos/{id} chỉ đổi tiêu đề, mô tả, danh mục (nguồn không đổi được); video đã qua kiểm duyệt
///   sẽ bị kiểm duyệt lại. Bản nháp có thêm "Lưu và gửi duyệt".
class VideoFormScreen extends StatefulWidget {
  final Video? existing; // null = đăng mới
  const VideoFormScreen({super.key, this.existing});

  @override
  State<VideoFormScreen> createState() => _VideoFormScreenState();
}

class _VideoFormScreenState extends State<VideoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  final _youtube = TextEditingController();

  List<CategoryItem> _categories = [];
  int? _categoryId;
  bool _isFile = false; // false = link YouTube
  XFile? _file;
  int _fileBytes = 0;
  String? _fileError;
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  double? _progress; // 0..1 khi đang tải tệp lên

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _youtube.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final cats = await context.read<HomeRepository>().categories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        final cid = widget.existing?.categoryId;
        _categoryId = cats.any((c) => c.id == cid) ? cid : null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được danh mục');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (f == null) return;
      final bytes = await f.length();
      if (!mounted) return;
      setState(() {
        _file = f;
        _fileBytes = bytes;
        _fileError = validateVideoFile(name: f.name.isNotEmpty ? f.name : f.path, bytes: bytes);
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không chọn được video');
    }
  }

  /// [publish]: đăng mới -> kiểm duyệt ngay; sửa bản nháp -> gửi duyệt sau khi lưu.
  Future<void> _save({required bool publish}) async {
    final formOk = _form.currentState!.validate();
    if (!_isEdit && _isFile) {
      if (_file == null) {
        setState(() => _fileError = 'Vui lòng chọn tệp video');
        return;
      }
      if (_fileError != null) return;
    }
    if (!formOk) return;

    setState(() {
      _busy = true;
      _progress = null;
    });
    final repo = context.read<VideoRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    try {
      Video result;
      if (_isEdit) {
        result = await repo.update(widget.existing!.id,
            title: _title.text.trim(),
            description: _description.text.trim(),
            categoryId: _categoryId!);
        if (publish && widget.existing!.status == 'DRAFT') result = await repo.submit(result.id);
      } else {
        final f = _file;
        result = await repo.create(
          title: _title.text.trim(),
          description: _description.text.trim(),
          categoryId: _categoryId!,
          youtubeUrl: _isFile ? null : _youtube.text.trim(),
          filePath: _isFile ? f!.path : null,
          fileName: _isFile ? (f!.name.isNotEmpty ? f.name : 'video.mp4') : null,
          publish: publish,
          onSendProgress: (sent, total) {
            if (mounted && total > 0) setState(() => _progress = sent / total);
          },
        );
      }
      if (!mounted) return;
      final out = videoOutcome(result);
      Navigator.of(context).pop(result);
      // Thông báo đúng theo trạng thái BE trả về (đã đăng / chờ duyệt / bị từ chối / nháp).
      if (out.needsDialog && rootContext.mounted) {
        showInfoDialog(rootContext, out.title, out.message);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(out.message)));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được video');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa video' : 'Đăng video')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RetryView(onRetry: _load)
              : AbsorbPointer(
                  absorbing: _busy,
                  child: Form(
                    key: _form,
                    child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                      if (_isEdit)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(e!.isYoutube ? LucideIcons.link : LucideIcons.fileVideo, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    'Nguồn video (${e.isYoutube ? 'YouTube' : 'tệp MP4'}) không đổi được. Bạn chỉ sửa được tiêu đề, mô tả và danh mục.',
                                    style: const TextStyle(fontSize: 13))),
                          ]),
                        )
                      else ...[
                        FullWidthSegmented<bool>(
                          options: const [
                            SegmentOption(false, 'Link YouTube', icon: LucideIcons.link),
                            SegmentOption(true, 'Tệp MP4', icon: LucideIcons.fileVideo),
                          ],
                          selected: _isFile,
                          onChanged: (v) => setState(() => _isFile = v),
                        ),
                        const SizedBox(height: 12),
                        if (_isFile) _filePicker() else _youtubeField(),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        maxLength: VideoLimits.titleMax,
                        decoration: const InputDecoration(
                            labelText: 'Tiêu đề', prefixIcon: Icon(LucideIcons.type), counterText: ''),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        maxLines: 4,
                        maxLength: VideoLimits.descriptionMax,
                        decoration: const InputDecoration(
                            labelText: 'Mô tả (không bắt buộc)', alignLabelWithHint: true, counterText: ''),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Danh mục', prefixIcon: Icon(LucideIcons.tag)),
                        items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                      ),
                      const SizedBox(height: 20),
                      if (_progress != null) ...[
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 6),
                        Text('Đang tải lên ${(_progress! * 100).round()}%...',
                            style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                        const SizedBox(height: 12),
                      ],
                      if (!_isEdit || e!.status == 'DRAFT')
                        FilledButton.icon(
                          onPressed: _busy ? null : () => _save(publish: true),
                          icon: const Icon(LucideIcons.send),
                          label: Text(_isEdit ? 'Lưu và gửi duyệt' : 'Đăng video'),
                        ),
                      if (!_isEdit || e!.status == 'DRAFT') const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _save(publish: false),
                        icon: _busy && _progress == null
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.save),
                        label: Text(_isEdit ? 'Lưu thay đổi' : 'Lưu nháp'),
                      ),
                      if (_isEdit && e!.status == 'PUBLISHED')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Video đã đăng sẽ được kiểm duyệt lại sau khi sửa.',
                              style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                        ),
                    ]),
                  ),
                ),
    );
  }

  Widget _youtubeField() => TextFormField(
        controller: _youtube,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
            labelText: 'Link YouTube',
            hintText: 'https://www.youtube.com/watch?v=...',
            prefixIcon: Icon(LucideIcons.link)),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return 'Vui lòng nhập link YouTube';
          return extractYouTubeId(t) == null
              ? 'Link YouTube không hợp lệ (youtu.be, watch?v=, /embed/ hoặc /shorts/)'
              : null;
        },
      );

  Widget _filePicker() {
    final f = _file;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OutlinedButton.icon(
        onPressed: _pickFile,
        icon: const Icon(LucideIcons.folderOpen),
        label: Text(f == null ? 'Chọn video .mp4 (tối đa 30MB)' : 'Chọn video khác'),
      ),
      if (f != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('${f.name.isNotEmpty ? f.name : File(f.path).uri.pathSegments.last} • ${formatFileSize(_fileBytes)}',
              style: TextStyle(color: context.textMuted)),
        ),
      if (_fileError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_fileError!, style: TextStyle(color: context.cs.error, fontSize: 13)),
        ),
    ]);
  }
}
