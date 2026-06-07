import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/camera.dart';
import 'camera_parse.dart';

/// Loads cameras from bundled JSON shards under `assets/data/`.
class CameraDataService {
  static const dataAssets = [
    'assets/data/cameras.json',
    'assets/data/giraffe_cameras.json',
    'assets/data/wind_cameras.json',
  ];

  Future<List<Camera>> loadAll() async {
    final list = <Camera>[];
    for (final asset in dataAssets) {
      list.addAll(await _loadAsset(asset));
    }
    if (list.isEmpty) {
      throw StateError('No enabled cameras in bundled data assets');
    }
    list.sort((a, b) {
      final country = a.country.compareTo(b.country);
      if (country != 0) return country;
      final city = a.city.compareTo(b.city);
      if (city != 0) return city;
      final cat = a.category.name.compareTo(b.category.name);
      if (cat != 0) return cat;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Future<List<Camera>> _loadAsset(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final list = raw.length > 300000
          ? await compute(parseCameraAssetJson, raw)
          : parseCameraAssetJson(raw);
      return list;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Unable to load asset') || msg.contains('Asset not found')) {
        throw StateError(
          'Missing $asset — run: flutter pub get, then stop and run flutter run again (not hot reload).',
        );
      }
      throw StateError('Failed to read $asset: $e');
    }
  }
}
