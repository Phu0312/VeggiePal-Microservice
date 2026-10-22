import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Nhận diện loại ảnh ('jpeg' | 'png' | 'webp') theo byte đầu file, không tin vào đuôi tên file
/// (ảnh có thể đã bị nén lại). Trả về null nếu không phải JPEG/PNG/WEBP.
String? sniffImageType(Uint8List b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'jpeg';
  if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'png';
  if (b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'webp';
  }
  return null;
}

/// Tạo phần multipart cho ảnh với Content-Type khớp nội dung thật (backend kiểm tra cả hai).
MultipartFile imagePart(Uint8List bytes, String type) => MultipartFile.fromBytes(bytes,
    filename: 'image.${type == 'jpeg' ? 'jpg' : type}', contentType: DioMediaType('image', type));
