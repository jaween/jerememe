import 'package:app/services/api_service.dart';
import 'package:app/services/models/frame.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'frames_repository.freezed.dart';
part 'frames_repository.g.dart';

@riverpod
class FramesRepository extends _$FramesRepository {
  int? _maxIndex;

  @override
  Stream<Frames> build(String mediaId, int baseFrameIndex) async* {
    _fetchInitialFrames();
  }

  void fetchStart() {
    final data = state.value;
    if (data == null) {
      return;
    }
    _fetchFrames(
      direction: FramesDirection.before,
      frameIndex: data.frames.first.index,
    );
  }

  void fetchEnd() {
    final data = state.value;
    if (data == null) {
      return;
    }
    _fetchFrames(
      direction: FramesDirection.after,
      frameIndex: data.frames.last.index,
    );
  }

  void _fetchInitialFrames() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.getFrames(
      mediaId: mediaId,
      index: baseFrameIndex,
      direction: null,
    );
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
      case Right(:final value):
        _maxIndex ??= value.meta.maxIndex;
        state = AsyncData(
          Frames(
            frames: List.of(value.data),
            isFetchingStart: false,
            isFetchingEnd: false,
          ),
        );
    }
  }

  void _fetchFrames({FramesDirection? direction, int? frameIndex}) async {
    final data = state.value;
    if (data == null) {
      return;
    }
    if (data.isFetching) {
      return;
    }

    final maxIndex = _maxIndex;
    if (frameIndex != null) {
      if (frameIndex <= 0 || (maxIndex != null && frameIndex >= maxIndex)) {
        return;
      }
    }

    switch (direction) {
      case FramesDirection.before:
        state = AsyncData(data.copyWith(isFetchingStart: true));
      case FramesDirection.after:
        state = AsyncData(data.copyWith(isFetchingEnd: true));
      case null:
        state = AsyncData(
          data.copyWith(isFetchingStart: false, isFetchingEnd: false),
        );
    }
    final api = ref.read(apiServiceProvider);
    final result = await api.getFrames(
      mediaId: mediaId,
      index: frameIndex ?? baseFrameIndex,
      direction: direction,
    );
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
      case Right(:final value):
        final newFrames = switch (direction) {
          FramesDirection.before => List.of(
            data.frames,
          )..insertAll(0, value.data),
          FramesDirection.after => List.of(data.frames)..addAll(value.data),
          null => value.data,
        };

        _maxIndex ??= value.meta.maxIndex;
        state = AsyncData(
          data.copyWith(
            frames: newFrames,
            isFetchingStart: false,
            isFetchingEnd: false,
          ),
        );
    }
  }
}

@freezed
abstract class Frames with _$Frames {
  const factory Frames({
    required List<Frame> frames,
    @Default(false) bool isFetchingStart,
    @Default(false) bool isFetchingEnd,
  }) = _Frames;

  const Frames._();

  bool get isFetching => isFetchingStart || isFetchingEnd;
}

@riverpod
AsyncValue<Frames> reducedFrames(Ref ref, String mediaId, int baseFrameIndex) {
  final value = ref.watch(framesRepositoryProvider(mediaId, baseFrameIndex));
  switch (value) {
    case AsyncLoading() || AsyncError():
      return value;
    case AsyncData(:final value):
      final frames = value.frames;
      final index = frames.indexWhere(((e) => e.index == baseFrameIndex));
      final framesBefore = frames.sublist(0, index).reversed.toList();
      final framesAfter = frames.sublist(index + 1);
      final sublistBefore = [];
      final sublistAfter = [];
      const skip = 6;
      for (int i = skip; i < framesBefore.length; i += skip) {
        sublistBefore.add(framesBefore[i]);
      }
      for (int i = skip; i < framesAfter.length; i += skip) {
        sublistAfter.add(framesAfter[i]);
      }
      return AsyncData(
        value.copyWith(
          frames: [...sublistBefore.reversed, frames[index], ...sublistAfter],
        ),
      );
  }
}
