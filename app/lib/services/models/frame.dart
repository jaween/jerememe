import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame.freezed.dart';
part 'frame.g.dart';

@freezed
abstract class Frame with _$Frame {
  const factory Frame({
    required int index,
    required String image,
    required Subtitle? subtitle,
  }) = _Frame;

  factory Frame.fromJson(Map<String, Object?> json) => _$FrameFromJson(json);
}

@freezed
abstract class Subtitle with _$Subtitle {
  const factory Subtitle({required int lineNumber, required String text}) =
      _Subtitle;

  factory Subtitle.fromJson(Map<String, Object?> json) =>
      _$SubtitleFromJson(json);
}

enum FramesDirection { before, after }

@freezed
abstract class FramesResponse with _$FramesResponse {
  const factory FramesResponse({
    required List<Frame> data,
    required FramesMeta meta,
  }) = _FramesResponse;

  factory FramesResponse.fromJson(Map<String, Object?> json) =>
      _$FramesResponseFromJson(json);
}

@freezed
abstract class FramesMeta with _$FramesMeta {
  const factory FramesMeta({required int maxIndex}) = _FramesMeta;

  factory FramesMeta.fromJson(Map<String, Object?> json) =>
      _$FramesMetaFromJson(json);
}
