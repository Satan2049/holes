import '../models/camera.dart';

bool isYoutubeStream(StreamType type) => type == StreamType.youtube;

bool isEmbedStream(StreamType type) =>
    type == StreamType.embed || type == StreamType.external;

bool isHlsStream(String url, StreamType type) {
  if (isYoutubeStream(type) || isEmbedStream(type)) return false;
  if (type == StreamType.hls) return true;
  if (type == StreamType.mjpeg) return false;
  return RegExp(r'\.m3u8(\?|$)', caseSensitive: false).hasMatch(url);
}

String? youtubeVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.host.contains('youtube.com')) {
    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        (segments[0] == 'embed' || segments[0] == 'live' || segments[0] == 'shorts')) {
      return segments[1];
    }
    // @channel/live URLs have no stable video id — caller uses streamUrl in WebView.
    if (segments.length >= 2 && segments[0].startsWith('@') && segments[1] == 'live') {
      return null;
    }
  }
  return null;
}

/// Embed URL for YouTube — watch links use nocookie embed; channel /live uses full URL.
String youtubeEmbedTarget(String streamUrl, String? videoId, {required bool autoplay}) {
  if (videoId != null) {
    final ap = autoplay ? '1' : '0';
    return 'https://www.youtube-nocookie.com/embed/$videoId'
        '?autoplay=$ap&playsinline=1&rel=0&modestbranding=1';
  }
  return streamUrl;
}

/// HTML embed page for YouTube — nocookie domain fixes Android WebView errors 150/152.
String youtubeEmbedHtml(String streamUrl, String? videoId, {required bool autoplay}) {
  final src = youtubeEmbedTarget(streamUrl, videoId, autoplay: autoplay);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body{margin:0;padding:0;background:#000;height:100%;overflow:hidden}
iframe{border:0;width:100%;height:100%}</style>
</head>
<body>
<iframe
  src="$src"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen></iframe>
</body>
</html>''';
}

const int kMjpegRefreshCapMs = 10000;
const int kMjpegRefreshMinMs = 800;

int mjpegRefreshIntervalMs(int? updateRateMs) {
  final raw = updateRateMs ?? 1500;
  return raw.clamp(kMjpegRefreshMinMs, kMjpegRefreshCapMs);
}

bool mjpegRefreshIsCapped(int? updateRateMs) {
  final raw = updateRateMs ?? 1500;
  return raw > mjpegRefreshIntervalMs(updateRateMs);
}

String mjpegRefreshUri(String url, int tick) {
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}_t=$tick';
}
