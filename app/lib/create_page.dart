import 'package:app/services/api_service.dart';
import 'package:app/services/models/frame.dart';
import 'package:app/util.dart';
import 'package:app/widgets/video_player.dart';
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
  final _scrollController = ScrollController();
  final _frames = <Frame>[];
  int? _maxIndex;
  bool _isFetchingAfter = false;
  bool _isFetchingBefore = false;

  int? _startIndex;
  int? _endIndex;

  String? _url;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollUpdate);
    _fetchFrames();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return Scaffold(
      appBar: AppBar(),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _frames.length,
              itemBuilder: (context, index) {
                final frame = _frames[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_startIndex == null) {
                        _startIndex = frame.index;
                      } else {
                        if (_endIndex == null) {
                          _endIndex = frame.index;
                        } else {
                          _startIndex = frame.index;
                          _endIndex = null;
                        }
                      }
                    });
                  },
                  child: SizedBox(
                    key: ValueKey('${widget.mediaId}_${frame.index}'),
                    width: 150,
                    height: 125,
                    child: Image.network(frame.image),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Media ${widget.mediaId}, frame ${widget.frameIndex}'),
                  Text('Start Index $_startIndex'),
                  Text('End Index $_endIndex'),
                  FilledButton(
                    onPressed: _creating ? null : _postMeme,
                    child: Text('Generate'),
                  ),
                  SizedBox(
                    width: 500,
                    child: _creating
                        ? Center(child: CircularProgressIndicator())
                        : url != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              MemeVideoPlayer(url: url),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _copy(url),
                                    label: Text(url.substring(0, 20)),
                                    icon: Icon(Icons.copy),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
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

  void _onScrollUpdate() {
    if (!_scrollController.hasClients) {
      return;
    }

    const fetchTrigger = 200;

    // After
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - fetchTrigger &&
        !_isFetchingAfter &&
        position.userScrollDirection == ScrollDirection.reverse) {
      final lastFrame = _frames.isNotEmpty ? _frames.last.index : 0;
      _fetchFrames(direction: FramesDirection.after, frameIndex: lastFrame);
    }

    // Before
    if (position.pixels <= position.minScrollExtent + fetchTrigger &&
        !_isFetchingBefore &&
        position.userScrollDirection == ScrollDirection.forward) {
      final firstFrame = _frames.isNotEmpty ? _frames.first.index : 0;
      _fetchFrames(direction: FramesDirection.before, frameIndex: firstFrame);
    }
  }

  void _postMeme() async {
    final startIndex = _startIndex;
    final endIndex = _endIndex;
    if (startIndex == null || endIndex == null) {
      return;
    }

    final api = ref.read(apiServiceProvider);
    setState(() => _creating = true);
    final result = await api.postMeme(
      mediaId: widget.mediaId,
      startFrame: startIndex,
      endFrame: endIndex,
    );
    if (!mounted) {
      return;
    }
    setState(() => _creating = false);
    switch (result) {
      case Left(:final value):
        showError(context: context, message: value);
      case Right(:final value):
        setState(() => _url = value.data.url);
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
