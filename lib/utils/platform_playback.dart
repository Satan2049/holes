import 'package:flutter/foundation.dart';

import '../models/camera.dart';
import 'stream_utils.dart';

/// Web vs native playback limits (VPN does not fix CORS / HLS-on-Chrome).
abstract final class PlatformPlayback {
  static bool get isWeb => kIsWeb;

  static String get webWarning =>
      'Chrome/web: most .m3u8 (HLS) feeds cannot play here. '
      'MJPEG may work if the server allows CORS. '
      'Use an Android build for best results, or tap Open stream.';

  /// HTTPS + not blocked by browser mixed-content rules.
  static bool isHttps(Camera cam) => cam.streamUrl.startsWith('https://');

  /// Image/snapshot feeds — only type that sometimes works on web.
  static bool isMjpegStyle(Camera cam) =>
      !isHlsStream(cam.streamUrl, cam.streamType);

  /// Feeds more likely to work in Flutter web (still not guaranteed).
  static bool isWebFriendly(Camera cam) => isHttps(cam) && isMjpegStyle(cam);

  static String errorHint(Camera cam) {
    if (!isWeb) {
      return 'Stream offline, geo-blocked, or unsupported. Try Next.';
    }
    if (!isHttps(cam)) {
      return 'HTTP stream blocked in browser (mixed content). Use Android app.';
    }
    if (isHlsStream(cam.streamUrl, cam.streamType)) {
      return 'HLS (.m3u8) does not play in Chrome. Use Android app or Open stream.';
    }
    return 'Blocked by browser CORS or offline. Try Next or Open stream.';
  }
}
