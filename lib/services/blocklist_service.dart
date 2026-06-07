import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/camera.dart';

/// Bundled + session + user-persisted camera blocks.
class BlocklistService {
  BlocklistService._();
  static final BlocklistService instance = BlocklistService._();

  static const _asset = 'assets/data/blocklist.json';
  static const _keyUserIds = 'user_blocked_camera_ids';

  final Set<String> _bundledIds = {};
  final Set<String> _bundledUrls = {};
  final Set<String> _sessionIds = {};
  Set<String> _userIds = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_asset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _bundledIds
        ..clear()
        ..addAll((data['ids'] as List<dynamic>? ?? []).cast<String>());
      _bundledUrls
        ..clear()
        ..addAll((data['urls'] as List<dynamic>? ?? []).cast<String>());
    } catch (_) {
      // Missing or invalid blocklist is non-fatal.
    }
    final prefs = await SharedPreferences.getInstance();
    _userIds = (prefs.getStringList(_keyUserIds) ?? []).toSet();
    _loaded = true;
  }

  bool isBlocked(Camera cam) {
    if (_bundledIds.contains(cam.id)) return true;
    if (_sessionIds.contains(cam.id)) return true;
    if (_userIds.contains(cam.id)) return true;
    if (_bundledUrls.contains(cam.streamUrl)) return true;
    return false;
  }

  void blockSession(String id) => _sessionIds.add(id);

  void unblockSession(String id) => _sessionIds.remove(id);

  Future<void> blockPermanent(String id) async {
    _userIds.add(id);
    _sessionIds.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyUserIds, _userIds.toList());
  }

  int get sessionCount => _sessionIds.length;
}
