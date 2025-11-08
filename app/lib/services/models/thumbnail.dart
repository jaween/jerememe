import 'package:freezed_annotation/freezed_annotation.dart';

part 'thumbnail.freezed.dart';
part 'thumbnail.g.dart';

@freezed
abstract class Thumbnail with _$Thumbnail {
  const factory Thumbnail({
    required String url,
    @Default(480) int width,
    @Default(360) int height,
  }) = _Thumbnail;

  factory Thumbnail.fromJson(Map<String, Object?> json) =>
      _$ThumbnailFromJson(json);

  const Thumbnail._();

  double get aspectRatio => width / height;
}
