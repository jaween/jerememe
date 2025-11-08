import 'dart:math';

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchRepositoryProvider).value;
    if (results == null) {
      return SizedBox.shrink();
    }
    if (results.results.isEmpty && !results.searching) {
      return Center(child: Text('No results'));
    }
    final sidePadding = max(16.0, (MediaQuery.widthOf(context) - 1600) / 2);
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: sidePadding,
        right: sidePadding,
        bottom: 16,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
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
        return MouseRegion(
          key: ValueKey('${result.mediaId}_${result.startFrame}'),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
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
          ),
        );
      },
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
          AspectRatio(
            aspectRatio: result.thumbnail.aspectRatio,
            child: Image.network(
              result.thumbnail.url,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Shimmer(child: Container(color: Colors.grey.shade300));
              },
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  result.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: Colors.black,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: Colors.grey),
      ),
      child: child,
    );
  }
}
