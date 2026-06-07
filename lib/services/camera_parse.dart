import 'dart:convert';

import '../models/camera.dart';

List<Camera> parseCameraAssetJson(String raw) {
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return CameraIndex.fromJson(decoded).cameras.where((c) => c.enabled).toList();
}
