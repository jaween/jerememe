import 'dart:async';

import 'package:app/services/api_service.dart';
import 'package:app/services/models/search.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_repository.freezed.dart';
part 'search_repository.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return state;
  }

  void setQuery(String text) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      state = text.trim();
    });
  }
}

@riverpod
class SearchRepository extends _$SearchRepository {
  late int _offset;
  int? _totalResults;
  late String _query;

  @override
  Stream<SearchResults> build() async* {
    _query = ref.watch(searchQueryProvider);
    _offset = 0;
    _totalResults = null;
    if (_query.isEmpty) {
      return;
    }
    state = AsyncData(SearchResults(results: [], searching: true));
    _fetchInitialPage(_query);
  }

  Future<void> _fetchInitialPage(String query) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.getSearch(query: query);
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
        return;
      case Right(:final value):
        state = AsyncData(_Results(results: List.of(value.data)));
        _offset = value.data.length;
        _totalResults = value.meta.totalResults;
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.searching) {
      return;
    }

    final totalResults = _totalResults;
    if (!(totalResults == null || _offset < totalResults)) {
      return;
    }

    final api = ref.read(apiServiceProvider);
    state = AsyncData(currentState.copyWith(searching: true));
    final result = await api.getSearch(query: _query, offset: _offset);
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
        return;
      case Right(:final value):
        state = AsyncData(
          _Results(results: List.of(currentState.results)..addAll(value.data)),
        );
        _offset += value.data.length;
    }
  }
}

@freezed
abstract class SearchResults with _$SearchResults {
  const factory SearchResults({
    required List<SearchResult> results,
    @Default(false) bool searching,
  }) = _Results;
}
