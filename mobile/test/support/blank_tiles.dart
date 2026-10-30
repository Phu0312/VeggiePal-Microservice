import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:VeggiePal/features/places/presentation/places_map.dart';

// PNG trong suốt 1x1.
final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// Bộ tải ô bản đồ cho test: trả ảnh trong suốt thay vì gọi mạng (môi trường test trả HTTP 400 cho mọi ảnh mạng)
/// và không dùng path_provider để lưu đệm.
class BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_transparentPng);
}

MapTiles blankMapTiles() => MapTiles(BlankTileProvider());
