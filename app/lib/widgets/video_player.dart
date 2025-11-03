import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MemeVideoPlayer extends StatefulWidget {
  final String url;

  const MemeVideoPlayer({super.key, required this.url});

  @override
  State<MemeVideoPlayer> createState() => _MemeVideoPlayerState();
}

class _MemeVideoPlayerState extends State<MemeVideoPlayer> {
  late final _controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.play();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
