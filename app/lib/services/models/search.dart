import 'package:freezed_annotation/freezed_annotation.dart';

part 'search.freezed.dart';
part 'search.g.dart';

@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String mediaId,
    required int startTime,
    required int startFrame,
    required String text,
    required String image,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, Object?> json) =>
      _$SearchResultFromJson(json);
}

@freezed
abstract class SearchResponse with _$SearchResponse {
  const factory SearchResponse({required List<SearchResult> data}) =
      _SearchResponse;

  factory SearchResponse.fromJson(Map<String, Object?> json) =>
      _$SearchResponseFromJson(json);
}
