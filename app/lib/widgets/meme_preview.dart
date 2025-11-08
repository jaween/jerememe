import 'dart:async';

import 'package:app/services/models/frame.dart';
import 'package:app/widgets/proportional_font_size_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
      widget.frames.map(
        (e) => precacheImage(NetworkImage(e.thumbnail.url), context),
      ),
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
    return Builder(
      builder: (context) {
        if (widget.frames.isEmpty) {
          return const SizedBox.shrink();
        }
        return AspectRatio(
          aspectRatio: widget.frames.first.thumbnail.aspectRatio,
          child: Shimmer(
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
                      child: ExcludeFocus(
                        child: IgnorePointer(
                          child: ProportionalFontSizeBuilder(
                            builder: (context, fontSize) {
                              return TextFormField(
                                controller: widget.textController,
                                scrollPhysics: NeverScrollableScrollPhysics(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                minLines: 1,
                                maxLines: 4,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Impact',
                                  fontSize: fontSize,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 4
                                    ..color = Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ProportionalFontSizeBuilder(
                        builder: (context, fontSize) {
                          return TextFormField(
                            controller: widget.textController,
                            focusNode: _textFieldFocusNode,
                            inputFormatters: [CapitalizeTextInputFormatter()],
                            scrollPhysics: NeverScrollableScrollPhysics(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 4,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Impact',
                              fontSize: fontSize,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return Image.network(
      widget.frames[frameIndex].thumbnail.url,
      fit: BoxFit.contain,
    );
  }
}

class CapitalizeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
