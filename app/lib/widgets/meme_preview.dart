import 'dart:async';

import 'package:app/services/models/frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  final _textFieldFocusNode = FocusNode();
  bool _loading = true;
  bool _hasCached = false;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCached) {
      _hasCached = true;
      _cacheFrames();
    }
  }

  void _cacheFrames() async {
    await Future.wait(
      widget.frames.map((e) => precacheImage(NetworkImage(e.image), context)),
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    _textFieldFocusNode.requestFocus();
  }

  @override
  void dispose() {
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
                    _Playback(frames: widget.frames),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ExcludeFocus(
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: widget.textController,
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

class _Playback extends StatefulWidget {
  final List<Frame> frames;
  const _Playback({super.key, required this.frames});

  @override
  State<_Playback> createState() => _PlaybackState();
}

class _PlaybackState extends State<_Playback>
    with SingleTickerProviderStateMixin {
  static const _fps = 24;
  static const _frameDuration = Duration(milliseconds: 1000 ~/ _fps);

  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.frames.isNotEmpty) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    setState(() => _elapsed = elapsed);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const SizedBox.shrink();
    }
    final frameCount = widget.frames.length;
    final frameIndex =
        ((_elapsed.inMilliseconds ~/ _frameDuration.inMilliseconds) %
        frameCount);
    return Image.network(widget.frames[frameIndex].image, fit: BoxFit.contain);
  }
}
