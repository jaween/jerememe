import 'package:app/services/models/meme.dart';
import 'package:app/widgets/video_player.dart';
import 'package:flutter/material.dart';

class MemeDisplay extends StatefulWidget {
  final Meme meme;

  const MemeDisplay({super.key, required this.meme});

  @override
  State<MemeDisplay> createState() => _MemeDisplayState();
}

class _MemeDisplayState extends State<MemeDisplay> {
  @override
  Widget build(BuildContext context) {
    if (widget.meme.isVideo) {
      return MemeVideoPlayer(url: widget.meme.url);
    } else {
      return Image.network(widget.meme.url);
    }
  }
}
