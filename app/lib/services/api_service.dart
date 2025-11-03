import 'dart:async';
import 'dart:convert';

import 'package:app/services/models/search_result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service.g.dart';

@riverpod
ApiService apiService(Ref ref) => throw 'Uninitialized provider';

const _kTimeout = Duration(seconds: 10);

class ApiService {
  final String _baseUrl;
  late final Map<String, String> _headers;
  final http.Client _client;

  ApiService({required String baseUrl})
    : _baseUrl = baseUrl,
      _headers = {'content-type': 'application/json'},
      _client = http.Client();

  void dispose() => _client.close();

  Future<Either<String, List<SearchResult>>> search(String query) {
    final url = Uri.encodeFull('$_baseUrl/search?q="$query"');
    return _makeRequest(
      request: () => _client.get(Uri.parse(url), headers: _headers),
      handleResponse: (json) {
        final list = json as List;
        return Right(list.map((e) => SearchResult.fromJson(e)).toList());
      },
    );
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
      return handleResponse(json['data']);
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
