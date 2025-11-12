import 'dart:math';

import 'package:app/repositories/frames_repository.dart';
import 'package:app/repositories/search_repository.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/models/frame.dart';
import 'package:app/services/models/meme.dart';
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
        if (constraints.maxWidth < 864) {
          return Center(
            child: Container(
              width: 500,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: _MemeColumn(
                      key: _memePreviewColumnKey,
                      textController: _textController,
                      mediaId: widget.mediaId,
                      frames: _frames,
                      range: _range,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: _FramesColumn(
                      key: _framesColumnKey,
                      frames: _reducedFrames,
                      range: _range,
                      onRangeChanged: (range, frames) {
                        setState(() => _range = range);
                        _textController.text = _createCaption(frames);
                      },
                      center: true,
                      onFetchStart: ref.read(_provider.notifier).fetchStart,
                      onFetchEnd: ref.read(_provider.notifier).fetchEnd,
                    ),
                  ),
                  SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: !_frames.hasValue ? null : _postMeme,
                    icon: Icon(Icons.done),
                    label: Text('Finish'),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1196),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FramesColumn(
                  key: _framesColumnKey,
                  frames: _reducedFrames,
                  range: _range,
                  onRangeChanged: (range, frames) {
                    setState(() => _range = range);
                    _textController.text = _createCaption(frames);
                  },
                  center: false,
                  onFetchStart: ref.read(_provider.notifier).fetchStart,
                  onFetchEnd: ref.read(_provider.notifier).fetchEnd,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MemeColumn(
                                  key: _memePreviewColumnKey,
                                  textController: _textController,
                                  mediaId: widget.mediaId,
                                  frames: _frames,
                                  range: _range,
                                ),
                                SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: !_frames.hasValue
                                      ? null
                                      : _postMeme,
                                  icon: Icon(Icons.done),
                                  label: Text('Finish'),
                                ),
                              ],
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

  void _postMeme() async {
    final meme = await showDialog<Meme>(
      context: context,
      barrierDismissible: false,
      builder: (builder) {
        return _UploadDialog(
          mediaId: widget.mediaId,
          range: _range,
          text: _textController.text,
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (meme != null) {
      context.goNamed('viewer', pathParameters: {'id': meme.id});
    }
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
                AsyncLoading() => AspectRatio(
                  aspectRatio: 480 / 360,
                  child: Container(color: Colors.black),
                ),
                AsyncError(:final error) => Center(
                  child: Text(error.toString()),
                ),
                AsyncData(:final value) => MemePreview(
                  key: ValueKey(widget.range.hashCode),
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
      ],
    );
  }
}

class _FramesColumn extends StatelessWidget {
  final AsyncValue<Frames> frames;
  final _FrameRange range;
  final void Function(_FrameRange range, List<Frame> frames) onRangeChanged;
  final bool center;
  final VoidCallback onFetchStart;
  final VoidCallback onFetchEnd;

  const _FramesColumn({
    super.key,
    required this.frames,
    required this.range,
    required this.onRangeChanged,
    required this.center,
    required this.onFetchStart,
    required this.onFetchEnd,
  });

  @override
  Widget build(BuildContext context) {
    return switch (frames) {
      AsyncLoading() => SizedBox(
        width: 240,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            return Center(
              child: _FrameContainer(
                aspectRatio: 480 / 360,
                child: Container(color: Colors.black)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 1),
                      angle: 60 * (pi / 180),
                    ),
              ),
            );
          },
        ),
      ),
      AsyncError(:final error) => Center(child: Text(error.toString())),
      AsyncData(:final value) => LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _FrameRangePicker(
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
              center: center,
              height: constraints.maxHeight,
              frames: value.frames,
              isFetchingStart: value.isFetchingStart,
              isFetchingEnd: value.isFetchingEnd,
              onFetchStart: onFetchStart,
              onFetchEnd: onFetchEnd,
            ),
          );
        },
      ),
    };
  }
}

class _FrameRangePicker extends StatefulWidget {
  final _FrameRange range;
  final void Function(_FrameRange range) onRangeChanged;
  final List<Frame> frames;
  final bool center;
  final double height;
  final bool isFetchingStart;
  final bool isFetchingEnd;
  final VoidCallback onFetchStart;
  final VoidCallback onFetchEnd;

  const _FrameRangePicker({
    super.key,
    required this.range,
    required this.onRangeChanged,
    required this.frames,
    required this.center,
    required this.height,
    required this.isFetchingStart,
    required this.isFetchingEnd,
    required this.onFetchStart,
    required this.onFetchEnd,
  });

  @override
  State<_FrameRangePicker> createState() => _FrameRangePickerState();
}

class _FrameRangePickerState extends State<_FrameRangePicker> {
  late PageController _pageController = PageController(
    viewportFraction: _itemHeight / widget.height,
    initialPage: widget.frames.length ~/ 2,
  );
  bool _startEnabled = true;
  bool _endEnabled = true;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScrollUpdate);
  }

  @override
  void didUpdateWidget(covariant _FrameRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _itemHeight / widget.height,
        initialPage: widget.frames.length ~/ 2,
      );
      _pageController.addListener(_onScrollUpdate);
    }
    if (oldWidget.range != widget.range) {
      _updateTrimButtonState();
    }

    final oldFrames = oldWidget.frames;
    final newFrames = widget.frames;
    if (newFrames.length > oldFrames.length && oldFrames.isNotEmpty) {
      _maybeJumpDownToPreviousPosition(oldFrames, newFrames);
    }
  }

  void _maybeJumpDownToPreviousPosition(
    List<Frame> oldFrames,
    List<Frame> newFrames,
  ) {
    final insertedAtTop = newFrames.first.index != oldFrames.first.index;
    if (insertedAtTop && _pageController.hasClients) {
      final newFrameCount = newFrames.length - oldFrames.length;
      final current = _pageController.position.pixels;
      _pageController.jumpTo(current + _itemHeight * newFrameCount);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const itemWidth = 190.0;
    final stackWidth = widget.center ? 348.0 : 280.0;
    return Center(
      child: SizedBox(
        width: stackWidth,
        child: Stack(
          alignment: widget.center ? Alignment.center : Alignment.centerLeft,
          children: [
            SizedBox(
              width: itemWidth,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: widget.frames.length,
                itemBuilder: (context, index) {
                  final frame = widget.frames[index];
                  final selected =
                      frame.index >= widget.range.startFrame &&
                      frame.index <= widget.range.endFrame;
                  final isFirstSelected =
                      selected && frame.index == widget.range.startFrame;
                  final isLastSelected =
                      selected && frame.index == widget.range.endFrame;
                  return Center(
                    key: ValueKey(frame.index.toString()),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: _FrameContainer(
                          selected: selected,
                          isFirstSelected: isFirstSelected,
                          isLastSelected: isLastSelected,
                          aspectRatio: frame.thumbnail.aspectRatio,
                          child: Image.network(
                            frame.thumbnail.url,
                            fit: BoxFit.cover,
                            frameBuilder:
                                (
                                  context,
                                  child,
                                  frame,
                                  wasLoadedSynchronously,
                                ) {
                                  return AnimatedCrossFade(
                                    duration: Duration(milliseconds: 250),
                                    alignment: Alignment.center,
                                    crossFadeState: frame == 0
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    firstChild: child,
                                    secondChild: Center(
                                      child:
                                          Container(
                                                height: 140,
                                                color: Colors.black,
                                              )
                                              .animate(
                                                onPlay: (controller) =>
                                                    controller.repeat(),
                                              )
                                              .shimmer(
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                                angle: 60 * (pi / 180),
                                              ),
                                    ),
                                  );
                                },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IgnorePointer(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: itemWidth,
                height: _itemHeight,
                // Separated decorations to due to error "A borderRadius can only be given on borders with uniform colors"
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border(
                    top: _startEnabled
                        ? BorderSide(
                            color: ColorScheme.of(context).primary,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border(
                    bottom: _endEnabled
                        ? BorderSide(
                            color: ColorScheme.of(context).primary,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.center ? 260 : 178,
                  bottom: _itemHeight - 8,
                ),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  opacity: _startEnabled ? 1.0 : 0.0,
                  child: _CutButton(
                    onPressed: !_startEnabled
                        ? null
                        : () {
                            widget.onRangeChanged(
                              _FrameRange(
                                startFrame: widget
                                    .frames[_pageController.page?.round() ?? 0]
                                    .index,
                                endFrame: widget.range.endFrame,
                              ),
                            );
                          },
                    child: Text('Start'),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.center ? 260 : 178,
                  top: _itemHeight - 8,
                ),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  opacity: _endEnabled ? 1.0 : 0.0,
                  child: _CutButton(
                    onPressed: !_endEnabled
                        ? null
                        : () {
                            widget.onRangeChanged(
                              _FrameRange(
                                startFrame: widget.range.startFrame,
                                endFrame: widget
                                    .frames[_pageController.page?.round() ?? 0]
                                    .index,
                              ),
                            );
                          },
                    child: Text('End'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScrollUpdate() {
    if (!_pageController.hasClients) {
      return;
    }

    _updateTrimButtonState();

    const fetchTrigger = 200;
    final position = _pageController.position;

    // Start
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

  void _updateTrimButtonState() {
    final pageValue = _pageController.page?.round() ?? 0;
    final index = widget.frames[pageValue].index;
    final isStart = index == widget.range.startFrame;
    final isEnd = index == widget.range.endFrame;
    final isBeforeStart = index < widget.range.startFrame;
    final isAfterEnd = index > widget.range.endFrame;
    if (_startEnabled && (isStart || isAfterEnd)) {
      setState(() => _startEnabled = false);
    } else if (!_startEnabled && !isStart && !isAfterEnd) {
      setState(() => _startEnabled = true);
    }

    if (_endEnabled && (isEnd || isBeforeStart)) {
      setState(() => _endEnabled = false);
    } else if (!_endEnabled && !isEnd && !isBeforeStart) {
      setState(() => _endEnabled = true);
    }
  }
}

class _FrameContainer extends StatelessWidget {
  final bool selected;
  final bool isFirstSelected;
  final bool isLastSelected;
  final double aspectRatio;
  final Widget? child;

  const _FrameContainer({
    super.key,
    this.selected = false,
    this.isFirstSelected = false,
    this.isLastSelected = false,
    required this.aspectRatio,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: aspectRatio * _itemHeight,
      height: _itemHeight,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: !isFirstSelected ? Radius.zero : Radius.circular(12),
            topRight: !isFirstSelected ? Radius.zero : Radius.circular(12),
            bottomLeft: !isLastSelected ? Radius.zero : Radius.circular(12),
            bottomRight: !isLastSelected ? Radius.zero : Radius.circular(12),
          ),
          color: selected ? ColorScheme.of(context).primary : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: child,
        ),
      ),
    );
  }
}

class _CutButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _CutButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(minimumSize: Size(20, 40)),
      onPressed: onPressed,
      icon: RotatedBox(quarterTurns: 2, child: Icon(Icons.cut)),
      label: child,
    );
  }
}

class _FrameRange {
  final int startFrame;
  final int endFrame;

  _FrameRange({required this.startFrame, required this.endFrame});

  @override
  int get hashCode => Object.hash(startFrame, endFrame);

  @override
  bool operator ==(Object other) =>
      other is _FrameRange &&
      other.startFrame == startFrame &&
      other.endFrame == endFrame;
}

class _UploadDialog extends ConsumerStatefulWidget {
  final String mediaId;
  final _FrameRange range;
  final String text;

  const _UploadDialog({
    super.key,
    required this.mediaId,
    required this.range,
    required this.text,
  });

  @override
  ConsumerState<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<_UploadDialog> {
  final _uploadProgressNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _post();
  }

  void _post() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.postMeme(
      mediaId: widget.mediaId,
      startFrame: widget.range.startFrame,
      endFrame: widget.range.endFrame,
      text: widget.text,
      onProgress: (progress) => _uploadProgressNotifier.value = progress,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(value)));
        Navigator.of(context).pop();
      case Right(:final value):
        Navigator.of(context).pop(value.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(16),
      title: Text('Finishing...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: ValueListenableBuilder(
              valueListenable: _uploadProgressNotifier,
              builder: (context, value, child) {
                return LinearProgressIndicator(value: value);
              },
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

extension on Frames {
  Iterable<Frame> selectedFrames(_FrameRange range) {
    return frames.where(
      (e) => e.index >= range.startFrame && e.index <= range.endFrame,
    );
  }
}
