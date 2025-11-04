import 'package:freezed_annotation/freezed_annotation.dart';

part 'meme.freezed.dart';
part 'meme.g.dart';

@freezed
abstract class Meme with _$Meme {
  const factory Meme({required String url, required bool isVideo}) = _Meme;

  factory Meme.fromJson(Map<String, Object?> json) => _$MemeFromJson(json);
}

@freezed
abstract class MemeResponse with _$MemeResponse {
  const factory MemeResponse({required Meme data}) = _MemeResponse;

  factory MemeResponse.fromJson(Map<String, Object?> json) =>
      _$MemeResponseFromJson(json);
}
