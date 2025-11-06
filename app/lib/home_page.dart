import 'package:app/repositories/search_repository.dart';
import 'package:app/services/models/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Keep alive provider
    ref.listenManual(searchQueryProvider, fireImmediately: true, (_, _) {});
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
                    onChanged: ref.read(searchQueryProvider.notifier).setQuery,
                  ),
                  SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => ref
                        .read(searchQueryProvider.notifier)
                        .setQuery(_searchController.text),
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
                    final results = ref.watch(searchRepositoryProvider).value;
                    if (results == null) {
                      return SizedBox.shrink();
                    }
                    if (results.results.isEmpty && !results.searching) {
                      return Center(child: Text('No results'));
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
                      itemCount: results.searching && results.results.isEmpty
                          ? 10
                          : results.results.length,
                      itemBuilder: (context, index) {
                        if (results.results.isEmpty) {
                          return _SearchResultCardBorder(
                            child: Shimmer(child: SizedBox.expand()),
                          );
                        }
                        final result = results.results[index];
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

  void _onScrollUpdate() async {
    if (!_scrollController.hasClients) {
      return;
    }

    const fetchTrigger = 200;

    // After
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - fetchTrigger &&
        position.userScrollDirection == ScrollDirection.reverse) {
      ref.read(searchRepositoryProvider.notifier).fetchNextPage();
    }
  }
}

class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return _SearchResultCardBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            result.image,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Shimmer(child: Container(color: Colors.grey.shade300));
            },
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Text(
              result.text,
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

class _SearchResultCardBorder extends StatelessWidget {
  final Widget? child;

  const _SearchResultCardBorder({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.black54,
      ),
      child: child,
    );
  }
}
