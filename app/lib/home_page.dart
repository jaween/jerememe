import 'package:app/services/api_service.dart';
import 'package:app/services/models/search.dart';
import 'package:app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  List<SearchResult>? _results;
  final _scrollController = ScrollController();

  String _submittedQuery = '';
  int _totalResults = 0;
  int _offset = 0;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Jerememe'),
                  SizedBox(height: 32),
                  TextFormField(
                    controller: _searchController,
                    onFieldSubmitted: (_) => _onSearchSubmitted(),
                  ),
                  SizedBox(height: 32),
                  FilledButton(
                    onPressed: _onSearchSubmitted,
                    child: Text('Search'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1600),
                child: Builder(
                  builder: (context) {
                    if (results == null && !_isFetching) {
                      return SizedBox.shrink();
                    } else if (results == null && _isFetching) {
                      return Center(child: CircularProgressIndicator());
                    } else if (results != null && results.isEmpty) {
                      return Center(child: Text('No results'));
                    } else if (results == null) {
                      return Center(child: Text('Something went wrong'));
                    }
                    return GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 11 / 10,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return InkWell(
                          key: ValueKey(
                            'result_${result.mediaId}_${result.startFrame}',
                          ),
                          onTap: () {
                            context.pushNamed(
                              'create',
                              pathParameters: {
                                'mediaId': result.mediaId,
                                'frame': result.startFrame.toString(),
                              },
                            );
                          },
                          child: SearchResultCard(result: result),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchSubmitted() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _offset = 0;
      _totalResults = 0;
      _submittedQuery = query;
      _results?.clear();
    });
    _fetchPage(query: query, offset: 0);
  }

  Future<void> _fetchPage({required String query, required int offset}) async {
    final api = ref.read(apiServiceProvider);
    setState(() => _isFetching = true);
    final result = await api.getSearch(query: query, offset: offset);
    if (!mounted) {
      return;
    }
    setState(() => _isFetching = false);
    switch (result) {
      case Left(:final value):
        showError(context: context, message: value);
        return;
      case Right(:final value):
        setState(() {
          _totalResults = value.meta.totalResults;
          _offset += value.data.length;
          _results = (_results ?? [])..addAll(value.data);
        });
    }
  }

  void _onScrollUpdate() async {
    if (!_scrollController.hasClients) {
      return;
    }

    const fetchTrigger = 200;

    // After
    final position = _scrollController.position;
    if (!_isFetching &&
        position.pixels >= position.maxScrollExtent - fetchTrigger &&
        !_isFetching &&
        position.userScrollDirection == ScrollDirection.reverse &&
        _offset < _totalResults) {
      _fetchPage(query: _submittedQuery, offset: _offset);
    }
  }
}

class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.black54,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(result.image),
          SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Text(
              '${result.startFrame}: ${result.text}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
