import 'package:app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MemeDisplay extends StatefulWidget {
  final String url;

  const MemeDisplay({super.key, required this.url});

  @override
  State<MemeDisplay> createState() => _MemeDisplayState();
}

class _MemeDisplayState extends State<MemeDisplay> {
  bool? _isVideo;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final response = await http.head(Uri.parse(widget.url));
    if (!mounted) {
      return;
    }
    final isVideo =
        response.headers['content-type']?.startsWith('video') == true;
    setState(() => _isVideo = isVideo);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideo;
    if (isVideo == null) {
      return SizedBox.shrink();
    }
    return SizedBox(
      width: 500,
      child: Builder(
        builder: (context) {
          if (isVideo) {
            return MemeVideoPlayer(url: widget.url);
          } else {
            return Image.network(widget.url);
          }
        },
      ),
    );
  }
}
