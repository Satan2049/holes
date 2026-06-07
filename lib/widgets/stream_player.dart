import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/camera.dart';
import '../models/stream_health.dart';
import '../theme/app_theme.dart';
import '../utils/platform_playback.dart';
import '../utils/stream_utils.dart';
import 'stream_health_badge.dart';

class StreamPlayer extends StatefulWidget {
  const StreamPlayer({
    super.key,
    required this.camera,
    required this.autoplay,
    this.onHealthChanged,
    this.onSkipAndHide,
    this.showHealthBadge = true,
  });

  final Camera camera;
  final bool autoplay;
  final ValueChanged<StreamHealth>? onHealthChanged;
  final VoidCallback? onSkipAndHide;
  final bool showHealthBadge;

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _error = false;
  String? _errorDetail;
  int _mjpegTick = 0;
  Timer? _mjpegTimer;
  StreamHealth _health = StreamHealth.loading;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(StreamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera.id != widget.camera.id) {
      _disposePlayer();
      _initPlayer();
    }
  }

  void _setHealth(StreamHealth health) {
    if (_health == health) return;
    _health = health;
    widget.onHealthChanged?.call(health);
  }

  Future<void> _initPlayer() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorDetail = null;
    });
    _setHealth(StreamHealth.loading);

    final cam = widget.camera;

    if (isYoutubeStream(cam.streamType)) {
      if (mounted) setState(() => _loading = false);
      _setHealth(StreamHealth.youtube);
      return;
    }

    if (isEmbedStream(cam.streamType)) {
      if (mounted) setState(() => _loading = false);
      _setHealth(StreamHealth.embed);
      return;
    }

    final url = cam.streamUrl;
    final useHls = isHlsStream(url, cam.streamType);

    if (PlatformPlayback.isWeb && useHls) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorDetail = PlatformPlayback.errorHint(cam);
        });
      }
      _setHealth(StreamHealth.error);
      return;
    }

    if (PlatformPlayback.isWeb && !PlatformPlayback.isHttps(cam)) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorDetail = PlatformPlayback.errorHint(cam);
        });
      }
      _setHealth(StreamHealth.error);
      return;
    }

    if (useHls) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      try {
        await controller.initialize();
        if (widget.autoplay) await controller.setLooping(true);
        if (widget.autoplay) await controller.play();
        if (mounted) setState(() => _loading = false);
        _setHealth(StreamHealth.live);
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = true;
            _errorDetail = PlatformPlayback.errorHint(cam);
          });
        }
        _setHealth(StreamHealth.error);
      }
      return;
    }

    final intervalMs = mjpegRefreshIntervalMs(cam.updateRateMs);
    _mjpegTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (mounted) setState(() => _mjpegTick++);
      },
    );
    if (mounted) setState(() => _loading = false);
    _setHealth(StreamHealth.snapshot);
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.camera.streamUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _disposePlayer() {
    _mjpegTimer?.cancel();
    _mjpegTimer = null;
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  String? get _snapshotHint {
    final cam = widget.camera;
    if (isHlsStream(cam.streamUrl, cam.streamType)) return null;
    if (isYoutubeStream(cam.streamType) || isEmbedStream(cam.streamType)) {
      return null;
    }
    if (mjpegRefreshIsCapped(cam.updateRateMs)) return '≤10s';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cam = widget.camera;

    if (isYoutubeStream(cam.streamType)) {
      final videoId = youtubeVideoId(cam.streamUrl);
      return _playerChrome(
        _YoutubeEmbedView(
          streamUrl: cam.streamUrl,
          videoId: videoId,
          autoplay: widget.autoplay,
          onReady: () => _setHealth(StreamHealth.youtube),
          onError: () => _setHealth(StreamHealth.error),
        ),
      );
    }

    if (isEmbedStream(cam.streamType)) {
      return _playerChrome(
        _EmbedWebView(
          url: cam.streamUrl,
          onReady: () => _setHealth(StreamHealth.embed),
        ),
      );
    }

    if (_error) {
      return _playerChrome(
        _StreamError(
          message: _errorDetail ?? 'Stream unavailable',
          streamUrl: cam.streamUrl,
          onOpen: _openExternally,
          onSkipAndHide: widget.onSkipAndHide,
        ),
      );
    }

    final useHls = isHlsStream(cam.streamUrl, cam.streamType);

    return _playerChrome(
      ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (useHls && _controller != null && _controller!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (!useHls)
              Image.network(
                mjpegRefreshUri(cam.streamUrl, _mjpegTick),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _error = true;
                        _errorDetail = PlatformPlayback.errorHint(cam);
                      });
                      _setHealth(StreamHealth.error);
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _playerChrome(Widget child) {
    if (!widget.showHealthBadge) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: StreamHealthBadge(
            health: _health,
            snapshotHint: _snapshotHint,
          ),
        ),
      ],
    );
  }
}

class _YoutubeEmbedView extends StatefulWidget {
  const _YoutubeEmbedView({
    required this.streamUrl,
    required this.videoId,
    required this.autoplay,
    this.onReady,
    this.onError,
  });

  final String streamUrl;
  final String? videoId;
  final bool autoplay;
  final VoidCallback? onReady;
  final VoidCallback? onError;

  @override
  State<_YoutubeEmbedView> createState() => _YoutubeEmbedViewState();
}

class _YoutubeEmbedViewState extends State<_YoutubeEmbedView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(_YoutubeEmbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl ||
        oldWidget.videoId != widget.videoId) {
      setState(() => _loading = true);
      _controller = _buildController();
    }
  }

  WebViewController _buildController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
              widget.onReady?.call();
            }
          },
          onWebResourceError: (_) => widget.onError?.call(),
        ),
      );

    if (widget.videoId != null) {
      controller.loadHtmlString(
        youtubeEmbedHtml(widget.streamUrl, widget.videoId, autoplay: widget.autoplay),
        baseUrl: 'https://www.youtube-nocookie.com',
      );
    } else {
      controller.loadRequest(Uri.parse(widget.streamUrl));
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _EmbedWebView extends StatefulWidget {
  const _EmbedWebView({required this.url, this.onReady});

  final String url;
  final VoidCallback? onReady;

  @override
  State<_EmbedWebView> createState() => _EmbedWebViewState();
}

class _EmbedWebViewState extends State<_EmbedWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.url);
  }

  @override
  void didUpdateWidget(_EmbedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _loading = true);
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  WebViewController _buildController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
              widget.onReady?.call();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _StreamError extends StatelessWidget {
  const _StreamError({
    required this.message,
    required this.streamUrl,
    required this.onOpen,
    this.onSkipAndHide,
  });

  final String message;
  final String streamUrl;
  final VoidCallback onOpen;
  final VoidCallback? onSkipAndHide;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.void900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: AppColors.onSurfaceMuted, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Cannot play in app',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: AppColors.cyber400, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open in browser'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent),
              ),
              if (onSkipAndHide != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onSkipAndHide,
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('Skip & hide'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
