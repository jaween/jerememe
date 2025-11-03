import 'package:app/services/api_service.dart';
import 'package:app/services/models/search.dart';
import 'package:app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _results = <SearchResult>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 11 / 10,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return InkWell(
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

    final api = ref.read(apiServiceProvider);
    final result = await api.getSearch(query);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Left(:final value):
        showError(context: context, message: value);
      case Right(:final value):
        setState(
          () => _results
            ..clear()
            ..addAll(value.data),
        );
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
