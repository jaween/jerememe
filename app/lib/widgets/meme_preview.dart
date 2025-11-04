import 'dart:async';

import 'package:app/services/models/frame.dart';
import 'package:flutter/material.dart';

class MemePreview extends StatefulWidget {
  final List<Frame> frames;
  final TextEditingController textController;

  const MemePreview({
    super.key,
    required this.frames,
    required this.textController,
  });

  @override
  State<MemePreview> createState() => _MemePreviewState();
}

class _MemePreviewState extends State<MemePreview> {
  int _currentFrame = 0;
  Timer? _timer;
  final _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.frames.isNotEmpty) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    const frameDuration = Duration(milliseconds: 1000 ~/ 24);
    _timer = Timer.periodic(frameDuration, (timer) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % widget.frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const SizedBox.shrink();
    }
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onTap: _textFieldFocusNode.requestFocus,
        child: SizedBox(
          width: 400,
          height: 300,
          child: Stack(
            children: [
              Image.network(
                widget.frames[_currentFrame].image,
                fit: BoxFit.contain,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: TextFormField(
                    controller: widget.textController,
                    minLines: 1,
                    maxLines: 4,
                    scrollPhysics: NeverScrollableScrollPhysics(),
                    enabled: false,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(border: InputBorder.none),
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
              Align(
                alignment: Alignment.bottomCenter,
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
            ],
          ),
        ),
      ),
    );
  }
}
