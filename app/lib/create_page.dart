import 'dart:math';

import 'package:app/services/api_service.dart';
import 'package:app/services/models/frame.dart';
import 'package:app/services/models/meme.dart';
import 'package:app/util.dart';
import 'package:app/widgets/meme_display.dart';
import 'package:app/widgets/meme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatePage extends ConsumerStatefulWidget {
  final String mediaId;
  final int frameIndex;

  const CreatePage({
    super.key,
    required this.mediaId,
    required this.frameIndex,
  });

  @override
  ConsumerState<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends ConsumerState<CreatePage> {
  final _frames = <Frame>[];
  int? _maxIndex;
  final _textController = TextEditingController();

  late _FrameRange _range = _FrameRange(
    startFrame: widget.frameIndex,
    endFrame: widget.frameIndex,
  );
  bool _isFetchingAfter = false;
  bool _isFetchingBefore = false;
  final _uploadProgressNotifier = ValueNotifier<double>(0);

  Meme? _meme;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchFrames();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meme = _meme;
    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: _FrameRangePicker(
              range: _range,
              onRangeChanged: (range) => setState(() => _range = range),
              isFetchingBefore: _isFetchingBefore,
              isFetchingAfter: _isFetchingAfter,
              frames: List.of(_frames),
              onFetchFrames: _fetchFrames,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        if (_creating) {
                          return Center(
                            child: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: _uploadProgressNotifier,
                                    builder: (context, value, child) {
                                      return LinearProgressIndicator(
                                        value: value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (meme == null) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MemePreview(
                                key: ValueKey(_range.hashCode),
                                textController: _textController,
                                frames: _frames
                                    .where(
                                      (e) =>
                                          e.index >= _range.startFrame &&
                                          e.index <= _range.endFrame,
                                    )
                                    .toList(),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ValueListenableBuilder(
                                  valueListenable: _textController,
                                  builder: (context, value, child) {
                                    return TextButton.icon(
                                      onPressed: value.text.isEmpty
                                          ? null
                                          : _textController.clear,
                                      label: Text('Remove text'),
                                      icon: Icon(Icons.clear),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return MemeDisplay(meme: meme);
                      },
                    ),
                    if (meme != null) ...[
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _copy(meme.url),
                        label: Text(meme.url.substring(0, 20)),
                        icon: Icon(Icons.copy),
                      ),
                    ],
                    SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _creating ? null : _postMeme,
                      label: Text('Generate'),
                      icon: Icon(Icons.done),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fetchFrames({FramesDirection? direction, int? frameIndex}) async {
    final maxIndex = _maxIndex;
    if (frameIndex != null) {
      if (frameIndex <= 0 || (maxIndex != null && frameIndex >= maxIndex)) {
        return;
      }
    }
    final api = ref.read(apiServiceProvider);
    switch (direction) {
      case FramesDirection.before:
        setState(() => _isFetchingBefore = true);
      case FramesDirection.after:
        setState(() => _isFetchingAfter = true);
      case null:
        setState(() {
          _isFetchingBefore = true;
          _isFetchingAfter = true;
        });
    }
    final result = await api.getFrames(
      mediaId: widget.mediaId,
      index: frameIndex ?? widget.frameIndex,
      direction: direction,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isFetchingBefore = false;
      _isFetchingAfter = false;
    });
    switch (result) {
      case Left(:final value):
        showError(context: context, message: value);
      case Right(:final value):
        final newFrames = switch (direction) {
          FramesDirection.before => List.of(_frames)..insertAll(0, value.data),
          FramesDirection.after => List.of(_frames)..addAll(value.data),
          null => value.data,
        };
        setState(() {
          _maxIndex ??= value.meta.maxIndex;
          _frames
            ..clear()
            ..addAll(newFrames);
        });
    }
  }

  void _postMeme() async {
    final startIndex = _range.startFrame;
    final endIndex = _range.endFrame;
    final text = _textController.text;
    _uploadProgressNotifier.value = 0;

    final api = ref.read(apiServiceProvider);
    setState(() => _creating = true);
    final result = await api.postMeme(
      mediaId: widget.mediaId,
      startFrame: startIndex,
      endFrame: endIndex,
      text: text,
      onProgress: (progress) {
        _uploadProgressNotifier.value = progress;
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _creating = false);
    switch (result) {
      case Left(:final value):
        showError(context: context, message: value);
      case Right(:final value):
        setState(() => _meme = value.data);
    }
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied To Clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FrameRangePicker extends StatefulWidget {
  final _FrameRange range;
  final bool isFetchingBefore;
  final bool isFetchingAfter;
  final void Function(_FrameRange range) onRangeChanged;
  final List<Frame> frames;
  final void Function({FramesDirection? direction, int? frameIndex})
  onFetchFrames;

  const _FrameRangePicker({
    super.key,
    required this.range,
    required this.onRangeChanged,
    required this.isFetchingBefore,
    required this.isFetchingAfter,
    required this.frames,
    required this.onFetchFrames,
  });

  @override
  State<_FrameRangePicker> createState() => _FrameRangePickerState();
}

class _FrameRangePickerState extends State<_FrameRangePicker> {
  final _scrollController = ScrollController();
  bool _justSetStart = false;
  bool _initialJumpDone = false;

  static const _itemHeight = 140.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FrameRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frames.isNotEmpty && !_initialJumpDone) {
      _performInitialJumpNextFrame();
    }
    final oldFrames = oldWidget.frames;
    final newFrames = widget.frames;
    if (newFrames.length > oldFrames.length && oldFrames.isNotEmpty) {
      _maybeJumpDownToPreviousPosition(oldFrames, newFrames);
    }
  }

  void _performInitialJumpNextFrame() async {
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && _scrollController.hasClients) {
      final viewport = _scrollController.position.viewportDimension;
      _scrollController.jumpTo(
        _itemHeight * widget.frames.length / 2 - viewport / 2,
      );
      setState(() => _initialJumpDone = true);
    }
  }

  void _maybeJumpDownToPreviousPosition(
    List<Frame> oldFrames,
    List<Frame> newFrames,
  ) {
    final insertedAtTop = newFrames.first.index != oldFrames.first.index;
    if (insertedAtTop && _scrollController.hasClients) {
      final newFrameCount = newFrames.length - oldFrames.length;
      final current = _scrollController.position.pixels;
      _scrollController.jumpTo(current + _itemHeight * newFrameCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _initialJumpDone ? 1.0 : 0.0,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.frames.length,
        itemBuilder: (context, index) {
          final frame = widget.frames[index];
          final selected =
              frame.index >= widget.range.startFrame &&
              frame.index <= widget.range.endFrame;
          return InkWell(
            key: ValueKey(frame.index.toString()),
            onTap: () {
              if (!_justSetStart) {
                widget.onRangeChanged(
                  _FrameRange(startFrame: frame.index, endFrame: frame.index),
                );
                setState(() => _justSetStart = true);
              } else {
                widget.onRangeChanged(
                  _FrameRange(
                    startFrame: min(widget.range.startFrame, frame.index),
                    endFrame: max(frame.index, widget.range.startFrame),
                  ),
                );
                setState(() => _justSetStart = false);
              }
            },
            child: Container(
              width: 180,
              height: _itemHeight,
              padding: const EdgeInsets.all(4.0),
              color: selected ? ColorScheme.of(context).primary : null,
              child: Image.network(frame.image),
            ),
          );
        },
      ),
    );
  }

  void _onScrollUpdate() {
    if (!_scrollController.hasClients) {
      return;
    }

    const fetchTrigger = 200;

    // After
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - fetchTrigger &&
        !widget.isFetchingAfter &&
        position.userScrollDirection == ScrollDirection.reverse) {
      final lastFrame = widget.frames.isNotEmpty ? widget.frames.last.index : 0;
      widget.onFetchFrames(
        direction: FramesDirection.after,
        frameIndex: lastFrame,
      );
    }

    // Before
    if (position.pixels <= position.minScrollExtent + fetchTrigger &&
        !widget.isFetchingBefore &&
        position.userScrollDirection == ScrollDirection.forward) {
      final firstFrame = widget.frames.isNotEmpty
          ? widget.frames.first.index
          : 0;
      widget.onFetchFrames(
        direction: FramesDirection.before,
        frameIndex: firstFrame,
      );
    }
  }
}

class _FrameRange {
  final int startFrame;
  final int endFrame;

  _FrameRange({required this.startFrame, required this.endFrame});
}
