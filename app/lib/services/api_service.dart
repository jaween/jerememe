import 'dart:async';
import 'dart:convert';

import 'package:app/services/models/frame.dart';
import 'package:app/services/models/meme.dart';
import 'package:app/services/models/search.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service.g.dart';

@riverpod
ApiService apiService(Ref ref) => throw 'Uninitialized provider';

const _kTimeout = Duration(seconds: 15);

class ApiService {
  final String _baseUrl;
  late final Map<String, String> _headers;
  final http.Client _client;

  ApiService({required String baseUrl})
    : _baseUrl = baseUrl,
      _headers = {'content-type': 'application/json'},
      _client = http.Client();

  void dispose() => _client.close();

  Future<Either<String, SearchResponse>> getSearch({
    required String query,
    int offset = 0,
  }) {
    final queryString = [
      'q=${Uri.encodeQueryComponent(query)}',
      'offset=$offset',
    ].join('&');
    final url = Uri.parse('$_baseUrl/search?$queryString');
    return _makeRequest(
      request: () => _client.get(url, headers: _headers),
      handleResponse: (json) {
        return Right(SearchResponse.fromJson(json));
      },
    );
  }

  Future<Either<String, FramesResponse>> getFrames({
    required String mediaId,
    required int index,
    required FramesDirection? direction,
  }) {
    final query = [
      'media_id=$mediaId',
      'index=$index',
      if (direction != null) 'direction=${direction.name}',
    ].join('&');
    final url = Uri.encodeFull('$_baseUrl/media?$query');
    return _makeRequest(
      request: () => _client.get(Uri.parse(url), headers: _headers),
      handleResponse: (json) {
        return Right(FramesResponse.fromJson(json));
      },
    );
  }

  Future<Either<String, MemeResponse>> postMeme({
    required String mediaId,
    required int startFrame,
    required int endFrame,
    required String text,
    required void Function(double progress) onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl/meme');
    final request = http.Request('POST', uri)
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'mediaId': mediaId,
        'startFrame': startFrame,
        'endFrame': endFrame,
        'text': text,
      });

    try {
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        return Left('Server error');
      }

      final completer = Completer<Either<String, MemeResponse>>();
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data:')) {
          final jsonPayload = jsonDecode(line.substring(5).trim());
          final type = jsonPayload['type'];
          if (type == 'progress') {
            final progress = (jsonPayload['progress'] ?? 0).toDouble();
            onProgress(progress);
          } else if (type == 'complete') {
            completer.complete(Right(MemeResponse.fromJson(jsonPayload)));
            break;
          } else if (type == 'error') {
            completer.complete(
              Left(jsonPayload['message'] ?? 'Error occurred'),
            );
            break;
          }
        }
      }

      return completer.future;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      return Left('Something went wrong');
    }
  }

  Future<Either<String, T>> _makeRequest<T>({
    required Future<http.Response> Function() request,
    required Either<String, T> Function(dynamic json) handleResponse,
  }) async {
    try {
      final response = await request().timeout(_kTimeout);
      try {
        return _decodeResponse(response, handleResponse: handleResponse);
      } catch (e, s) {
        debugPrint('Decoding response failed:');
        debugPrint(response.body);
        debugPrint(e.toString());
        debugPrint(s.toString());
        rethrow;
      }
    } on http.ClientException catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      return Left('Connection error occurred');
    } on TimeoutException {
      return Left('Connection problem');
    } catch (e) {
      debugPrint(e.toString());
      return Left('Something went wrong');
    }
  }

  Either<String, T> _decodeResponse<T>(
    http.Response response, {
    required Either<String, T> Function(dynamic json) handleResponse,
  }) {
    final json = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return handleResponse(json);
    }
    debugPrint('[API] Response status code was ${response.statusCode}');
    return Left('Something went wrong');
  }
}

sealed class Either<L, R> {
  const Either();

  const factory Either.left(L value) = Left<L, R>;
  const factory Either.right(R value) = Right<L, R>;

  T fold<T>({
    required T Function(L left) left,
    required T Function(R right) right,
  }) {
    final self = this;
    return switch (self) {
      Left() => left(self.value),
      Right() => right(self.value),
    };
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);
}
