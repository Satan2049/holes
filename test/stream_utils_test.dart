import 'package:flutter_test/flutter_test.dart';
import 'package:holes/models/camera.dart';
import 'package:holes/utils/stream_utils.dart';

void main() {
  test('isHlsStream detects m3u8 and streamType', () {
    expect(
      isHlsStream('https://x.com/a.m3u8', StreamType.auto),
      isTrue,
    );
    expect(
      isHlsStream('https://x.com/a.m3u8', StreamType.hls),
      isTrue,
    );
    expect(
      isHlsStream('https://x.com/cam.jpg', StreamType.mjpeg),
      isFalse,
    );
    expect(
      isHlsStream('https://youtu.be/x', StreamType.youtube),
      isFalse,
    );
  });

  test('youtubeVideoId parses watch and youtu.be URLs', () {
    expect(
      youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      'dQw4w9WgXcQ',
    );
    expect(youtubeVideoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(
      youtubeVideoId('https://www.youtube.com/embed/abc123'),
      'abc123',
    );
  });

  test('youtubeVideoId returns null for channel live URLs', () {
    expect(
      youtubeVideoId('https://www.youtube.com/@WebCamNL/live'),
      isNull,
    );
  });

  test('mjpeg refresh interval is capped at 10s', () {
    expect(mjpegRefreshIntervalMs(60_000), 10_000);
    expect(mjpegRefreshIntervalMs(1500), 1500);
    expect(mjpegRefreshIntervalMs(null), 1500);
    expect(mjpegRefreshIsCapped(60_000), isTrue);
  });

  test('youtubeEmbedTarget uses embed for video id', () {
    final url = youtubeEmbedTarget(
      'https://www.youtube.com/watch?v=abc',
      'abc',
      autoplay: true,
    );
    expect(url, contains('youtube-nocookie.com/embed/abc'));
    expect(url, contains('autoplay=1'));
  });
}
