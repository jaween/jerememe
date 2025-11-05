import 'dart:async';

import 'package:app/services/models/frame.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class MemePreview extends StatefulWidget {
  final List<Frame> frames;
  final TextEditingController textController;
  final bool autofocus;

  const MemePreview({
    super.key,
    required this.frames,
    required this.textController,
    this.autofocus = true,
  });

  @override
  State<MemePreview> createState() => _MemePreviewState();
}

class _MemePreviewState extends State<MemePreview> {
  int _currentFrame = 0;
  Timer? _timer;
  final _textFieldFocusNode = FocusNode();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.frames.isNotEmpty) {
      _startAnimation();
    }
    _cacheFrames();
  }

  void _startAnimation() {
    const frameDuration = Duration(milliseconds: 1000 ~/ 24);
    _timer = Timer.periodic(frameDuration, (timer) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % widget.frames.length;
      });
    });
  }

  void _cacheFrames() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.wait(
      widget.frames.map((e) => precacheImage(NetworkImage(e.image), context)),
    );
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 400,
      child: Builder(
        builder: (context) {
          if (widget.frames.isEmpty) {
            return const SizedBox.shrink();
          }
          return Shimmer(
            enabled: _loading,
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: GestureDetector(
                onTap: _textFieldFocusNode.requestFocus,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.frames[_currentFrame].image,
                      fit: BoxFit.contain,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: widget.textController,
                            autofocus: widget.autofocus,
                            minLines: 1,
                            maxLines: 4,
                            scrollPhysics: NeverScrollableScrollPhysics(),
                            enabled: false,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontFamily: 'Impact',
                              fontSize: 26,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: widget.textController,
                          focusNode: _textFieldFocusNode,
                          minLines: 1,
                          maxLines: 4,
                          scrollPhysics: NeverScrollableScrollPhysics(),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(border: InputBorder.none),
                          style: TextStyle(
                            fontFamily: 'Impact',
                            fontSize: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
