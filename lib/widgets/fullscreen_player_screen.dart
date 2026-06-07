import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/camera.dart';
import 'stream_player.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({
    super.key,
    required this.camera,
    required this.autoplay,
  });

  final Camera camera;
  final bool autoplay;

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            StreamPlayer(
              key: ValueKey('fs-${widget.camera.id}'),
              camera: widget.camera,
              autoplay: widget.autoplay,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Exit fullscreen',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
