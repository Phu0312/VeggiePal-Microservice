import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Sửa thông tin cá nhân: họ tên, số điện thoại, ngày sinh và ảnh đại diện.
/// Dữ liệu được nạp từ GET /users/me, lưu bằng PATCH /users/me, ảnh bằng POST /users/me/avatar.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  UserProfile? _profile;
  DateTime? _dob;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final p = await context.read<ProfileRepository>().profile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _name.text = p.fullName;
        _phone.text = p.phone ?? '';
        _dob = p.dateOfBirth;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được hồ sơ');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now.subtract(const Duration(days: 1)), // backend yêu cầu ngày sinh trong quá khứ
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthController>();
    try {
      final p = await context.read<ProfileRepository>().updateProfile(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            dateOfBirth: _dob == null ? null : isoDate(_dob!),
          );
      auth.updateUser(fullName: p.fullName);
      if (!mounted) return;
      setState(() => _profile = p);
      showSnack(context, 'Đã cập nhật thông tin cá nhân');
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được thông tin');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthController>();
    final repo = context.read<ProfileRepository>();
    try {
      // Thu nhỏ ảnh trước khi gửi để không vượt giới hạn 2MB của backend.
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (file == null) return;
      setState(() => _uploading = true);
      final p = await repo.uploadAvatar(await file.readAsBytes());
      auth.updateUser(avatarUrl: p.avatarUrl);
      if (!mounted) return;
      setState(() => _profile = p);
      showSnack(context, 'Đã cập nhật ảnh đại diện');
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không đổi được ảnh đại diện');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_loadFailed || p == null)
              ? RetryView(onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      _avatar(p),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            hintText: 'Nhập họ và tên của bạn',
                            prefixIcon: Icon(LucideIcons.user)),
                        validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            hintText: 'Nhập số điện thoại (có thể để trống)',
                            prefixIcon: Icon(LucideIcons.phone)),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickDob,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Ngày sinh', prefixIcon: Icon(LucideIcons.calendar)),
                          child: Text(_dob == null ? 'Chọn ngày sinh' : fmtDate(_dob!),
                              style: TextStyle(color: _dob == null ? context.textMuted : null)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: p.email,
                        enabled: false,
                        decoration: const InputDecoration(
                            labelText: 'Email (không thể thay đổi)',
                            prefixIcon: Icon(LucideIcons.mail)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Lưu thay đổi'),
                        ),
                      ),
                    ]),
                  ),
                ),
    );
  }

  Widget _avatar(UserProfile p) {
    final user = AuthUser(
        id: p.id,
        email: p.email,
        fullName: p.fullName,
        role: p.role == 'ADMIN' ? UserRole.admin : UserRole.user,
        avatarUrl: p.avatarUrl);
    return Stack(children: [
      UserAvatar(user, radius: 52),
      if (_uploading)
        const Positioned.fill(child: Center(child: CircularProgressIndicator())),
      Positioned(
        right: 0,
        bottom: 0,
        child: Material(
          color: context.cs.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _uploading ? null : _pickAvatar,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(LucideIcons.camera, size: 18, color: context.cs.onPrimary),
            ),
          ),
        ),
      ),
    ]);
  }
}
