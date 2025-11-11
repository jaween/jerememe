import 'dart:math';

import 'package:app/repositories/frames_repository.dart';
import 'package:app/repositories/search_repository.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/models/frame.dart';
import 'package:app/util.dart';
import 'package:app/widgets/meme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _itemHeight = 140.0;

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
  AsyncValue<Frames> _reducedFrames = AsyncLoading();
  final _memePreviewColumnKey = GlobalKey();
  final _framesColumnKey = GlobalKey();

  late final _provider = framesRepositoryProvider(
    widget.mediaId,
    widget.frameIndex,
  );

  late _FrameRange _range = _FrameRange(
    startFrame: widget.frameIndex,
    endFrame: widget.frameIndex,
  );

  @override
  void initState() {
    super.initState();
    // Keep alive provider
    ref.listenManual(searchQueryProvider, fireImmediately: true, (_, _) {});

    ref.listenManual(_provider, fireImmediately: true, (previous, next) {
      if (!next.hasValue) {
        return;
      }
      setState(() => _frames = next);
    });

    ref.listenManual(
      reducedFramesProvider(widget.mediaId, widget.frameIndex),
      fireImmediately: true,
      (previous, next) {
        if (!next.hasValue) {
          return;
        }
        setState(() => _reducedFrames = next);
        if (_textController.text.isEmpty) {
          _textController.text = _createCaption(
            next.requireValue.selectedFrames(_range),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: _MemeColumn(
                      key: _memePreviewColumnKey,
                      textController: _textController,
                      mediaId: widget.mediaId,
                      frames: _frames,
                      range: _range,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: _FramesColumn(
                    key: _framesColumnKey,
                    frames: _reducedFrames,
                    range: _range,
                    onRangeChanged: (range, frames) {
                      setState(() => _range = range);
                      _textController.text = _createCaption(frames);
                    },
                    onFetchStart: ref.read(_provider.notifier).fetchStart,
                    onFetchEnd: ref.read(_provider.notifier).fetchEnd,
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1196),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 232,
                  child: _FramesColumn(
                    key: _framesColumnKey,
                    frames: _reducedFrames,
                    range: _range,
                    onRangeChanged: (range, frames) {
                      setState(() => _range = range);
                      _textController.text = _createCaption(frames);
                    },
                    onFetchStart: ref.read(_provider.notifier).fetchStart,
                    onFetchEnd: ref.read(_provider.notifier).fetchEnd,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 96,
                              minWidth: 0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 500),
                            child: _MemeColumn(
                              key: _memePreviewColumnKey,
                              textController: _textController,
                              mediaId: widget.mediaId,
                              frames: _frames,
                              range: _range,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 232),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    return subtitles.join('\n').toUpperCase();
  }
}

class _MemeColumn extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final String mediaId;
  final AsyncValue<Frames> frames;
  final _FrameRange range;

  const _MemeColumn({
    super.key,
    required this.textController,
    required this.mediaId,
    required this.frames,
    required this.range,
  });

  @override
  ConsumerState<_MemeColumn> createState() => _MemeColumnState();
}

class _MemeColumnState extends ConsumerState<_MemeColumn> {
  final _uploadProgressNotifier = ValueNotifier<double>(0);
  bool _creating = false;
  bool _autofocus = true;

  @override
  void didUpdateWidget(covariant _MemeColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _autofocus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Builder(
            builder: (context) {
              final child = switch (widget.frames) {
                AsyncLoading() => SizedBox.shrink(),
                AsyncError(:final error) => Center(
                  child: Text(error.toString()),
                ),
                AsyncData(:final value) => MemePreview(
                  key: ValueKey(widget.range.hashCode),
                  autofocus: _autofocus,
                  textController: widget.textController,
                  frames: value.selectedFrames(widget.range).toList(),
                ),
              };
              if (widget.frames is! AsyncLoading) {
                return child;
              }
              return child
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 1),
                    angle: 60 * (pi / 180),
                  );
            },
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder(
            valueListenable: widget.textController,
            builder: (context, value, child) {
              return TextButton.icon(
                onPressed: value.text.isEmpty
                    ? null
                    : widget.textController.clear,
                label: Text('Remove text'),
                icon: Icon(Icons.clear),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Builder(
            builder: (context) {
              if (!_creating) {
                return FilledButton.icon(
                  onPressed: _creating ? null : _postMeme,
                  label: Text('Finish'),
                  icon: Icon(Icons.done),
                );
              }
              return ValueListenableBuilder(
                valueListenable: _uploadProgressNotifier,
                builder: (context, value, child) {
                  return LinearProgressIndicator(value: value);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _postMeme() async {
    final startIndex = widget.range.startFrame;
    final endIndex = widget.range.endFrame;
    final text = widget.textController.text;
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
        context.pushNamed('viewer', pathParameters: {'id': value.data.id});
    }
  }
}

class _FramesColumn extends StatelessWidget {
  final AsyncValue<Frames> frames;
  final _FrameRange range;
  final void Function(_FrameRange range, List<Frame> frames) onRangeChanged;
  final VoidCallback onFetchStart;
  final VoidCallback onFetchEnd;

  const _FramesColumn({
    super.key,
    required this.frames,
    required this.range,
    required this.onRangeChanged,
    required this.onFetchStart,
    required this.onFetchEnd,
  });

  @override
  Widget build(BuildContext context) {
    return switch (frames) {
      AsyncLoading() => ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return _FrameContainer(
            aspectRatio: 480 / 360,
            child: Container(color: Colors.black)
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: const Duration(seconds: 1),
                  angle: 60 * (pi / 180),
                ),
          );
        },
      ),
      AsyncError(:final error) => Center(child: Text(error.toString())),
      AsyncData(:final value) => _FrameRangePicker(
        range: range,
        onRangeChanged: (range) {
          final frameCount = range.endFrame - range.startFrame;
          if (frameCount > 240) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Maximum length is 10 seconds')),
            );
          } else {
            onRangeChanged(range, value.selectedFrames(range).toList());
          }
        },
        frames: value.frames,
        isFetchingStart: value.isFetchingStart,
        isFetchingEnd: value.isFetchingEnd,
        onFetchStart: onFetchStart,
        onFetchEnd: onFetchEnd,
      ),
    };
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
  bool _initialJumpDone = false;

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
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemExtent: _itemHeight,
        itemCount: widget.frames.length,
        itemBuilder: (context, index) {
          final frame = widget.frames[index];
          final selected =
              frame.index >= widget.range.startFrame &&
              frame.index <= widget.range.endFrame;
          return Center(
            key: ValueKey(frame.index.toString()),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (widget.range.startFrame == widget.range.endFrame &&
                      frame.index == widget.range.startFrame) {
                    return;
                  }
                  final closerToTop =
                      (frame.index < widget.range.startFrame) ||
                      ((frame.index - widget.range.startFrame).abs() <
                          (frame.index - widget.range.endFrame).abs());
                  if (frame.index == widget.range.startFrame) {
                    widget.onRangeChanged(
                      _FrameRange(
                        startFrame: widget.frames[index + 1].index,
                        endFrame: widget.range.endFrame,
                      ),
                    );
                  } else if (frame.index == widget.range.endFrame) {
                    widget.onRangeChanged(
                      _FrameRange(
                        startFrame: widget.range.startFrame,
                        endFrame: widget.frames[index - 1].index,
                      ),
                    );
                  } else if (closerToTop) {
                    widget.onRangeChanged(
                      _FrameRange(
                        startFrame: frame.index,
                        endFrame: widget.range.endFrame,
                      ),
                    );
                  } else {
                    widget.onRangeChanged(
                      _FrameRange(
                        startFrame: widget.range.startFrame,
                        endFrame: frame.index,
                      ),
                    );
                  }
                },
                child: _FrameContainer(
                  selected: selected,
                  aspectRatio: frame.thumbnail.aspectRatio,
                  child: Image.network(
                    frame.thumbnail.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return child
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: const Duration(seconds: 1),
                            angle: 60 * (pi / 180),
                          );
                    },
                  ),
                ),
              ),
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

class _FrameContainer extends StatelessWidget {
  final bool selected;
  final double aspectRatio;
  final Widget? child;

  const _FrameContainer({
    super.key,
    this.selected = false,
    required this.aspectRatio,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: aspectRatio * _itemHeight,
      height: _itemHeight,
      padding: const EdgeInsets.all(4.0),
      color: selected ? ColorScheme.of(context).primary : null,
      child: SizedBox.expand(child: child),
    );
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
