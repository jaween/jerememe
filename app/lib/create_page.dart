import 'dart:math';

import 'package:app/repositories/frames_repository.dart';
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
  final _textController = TextEditingController();
  AsyncValue<Frames> _frames = AsyncLoading();

  late final _provider = framesRepositoryProvider(
    widget.mediaId,
    widget.frameIndex,
  );

  late _FrameRange _range = _FrameRange(
    startFrame: widget.frameIndex,
    endFrame: widget.frameIndex,
  );

  final _uploadProgressNotifier = ValueNotifier<double>(0);
  Meme? _meme;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(_provider, fireImmediately: true, (previous, next) {
      if (!next.hasValue) {
        return;
      }
      setState(() => _frames = next);
      if (_textController.text.isEmpty) {
        _textController.text = _createCaption(
          next.requireValue.selectedFrames(_range),
        );
      }
    });
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
            child: switch (_frames) {
              AsyncLoading() => Center(child: CircularProgressIndicator()),
              AsyncError(:final error) => Center(child: Text(error.toString())),
              AsyncData(:final value) => _FrameRangePicker(
                range: _range,
                onRangeChanged: (range) {
                  setState(() => _range = range);
                  _textController.text = _createCaption(
                    value.selectedFrames(range),
                  );
                },
                frames: value.frames,
                isFetchingStart: value.isFetchingStart,
                isFetchingEnd: value.isFetchingEnd,
                onFetchStart: ref.read(_provider.notifier).fetchStart,
                onFetchEnd: ref.read(_provider.notifier).fetchEnd,
              ),
            },
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
                              switch (_frames) {
                                AsyncLoading() => Center(
                                  child: CircularProgressIndicator(),
                                ),
                                AsyncError(:final error) => Center(
                                  child: Text(error.toString()),
                                ),
                                AsyncData(:final value) => MemePreview(
                                  key: ValueKey(_range.hashCode),
                                  textController: _textController,
                                  frames: value.selectedFrames(_range).toList(),
                                ),
                              },
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

  String _createCaption(Iterable<Frame> frames) {
    final usedLines = <int>{};
    final subtitles = <String>[];
    for (final frame in frames) {
      final subtitle = frame.subtitle;
      if (subtitle != null && !usedLines.contains(subtitle.lineNumber)) {
        usedLines.add(subtitle.lineNumber);
        subtitles.add(subtitle.text);
      }
    }
    return subtitles.join('\n');
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
  final void Function(_FrameRange range) onRangeChanged;
  final List<Frame> frames;
  final bool isFetchingStart;
  final bool isFetchingEnd;
  final VoidCallback onFetchStart;
  final VoidCallback onFetchEnd;

  const _FrameRangePicker({
    super.key,
    required this.range,
    required this.onRangeChanged,
    required this.frames,
    required this.isFetchingStart,
    required this.isFetchingEnd,
    required this.onFetchStart,
    required this.onFetchEnd,
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
    _performInitialJumpNextFrame();
  }

  @override
  void didUpdateWidget(covariant _FrameRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    // Start
    final position = _scrollController.position;
    if (!widget.isFetchingStart &&
        position.pixels <= position.minScrollExtent + fetchTrigger &&
        position.userScrollDirection == ScrollDirection.forward) {
      widget.onFetchStart();
    }

    // End
    if (!widget.isFetchingEnd &&
        position.pixels >= position.maxScrollExtent - fetchTrigger &&
        position.userScrollDirection == ScrollDirection.reverse) {
      widget.onFetchEnd();
    }
  }
}

class _FrameRange {
  final int startFrame;
  final int endFrame;

  _FrameRange({required this.startFrame, required this.endFrame});
}

extension on Frames {
  Iterable<Frame> selectedFrames(_FrameRange range) {
    return frames.where(
      (e) => e.index >= range.startFrame && e.index <= range.endFrame,
    );
  }
}
