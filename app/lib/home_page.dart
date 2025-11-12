import 'dart:math';

import 'package:app/repositories/search_repository.dart';
import 'package:app/services/models/search.dart';
import 'package:app/widgets/image.dart';
import 'package:app/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchTextController = TextEditingController();

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer(
            builder: (context, ref, child) {
              return SearchField(
                controller: _searchTextController,
                autofocus: true,
                onQuery: (query) {
                  ref.read(searchQueryProvider.notifier).setQuery(query);
                  context.goNamed('home');
                },
                onClear: () =>
                    ref.read(searchQueryProvider.notifier).setQuery(''),
              );
            },
          ),
        ),
        if (MediaQuery.widthOf(context) > 800)
          SizedBox(height: 32)
        else
          SizedBox(height: 16),
        Expanded(child: _HomePageContent()),
      ],
    );
  }
}

class _HomePageContent extends ConsumerStatefulWidget {
  const _HomePageContent({super.key});

  @override
  ConsumerState<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends ConsumerState<_HomePageContent> {
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
    final searchQuery = ref.watch(searchQueryProvider);
    final results = ref.watch(searchRepositoryProvider).value;
    if (results == null || searchQuery.isEmpty) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _AboutButton(),
        ),
      );
    }
    if (results.results.isEmpty && !results.searching) {
      return Center(
        child: Text('No results', style: TextTheme.of(context).titleLarge),
      );
    }
    final sidePadding = max(16.0, (MediaQuery.widthOf(context) - 1600) / 2);
    return Scrollbar(
      child: GridView.builder(
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
          childAspectRatio: 4 / 3,
        ),
        itemCount: results.searching && results.results.isEmpty
            ? 8
            : results.results.length,
        itemBuilder: (context, index) {
          if (results.results.isEmpty) {
            return _SearchResultCardBorder(
              child: ColoredBox(color: Colors.black)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 1),
                    angle: 60 * (pi / 180),
                  ),
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              result.thumbnail.url,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasLoadedSynchronously) {
                return AnimatedCrossFade(
                  duration: Duration(milliseconds: 250),
                  alignment: Alignment.center,
                  layoutBuilder: animatedCrossFadeFilledLayoutBuilder,
                  crossFadeState: frame == 0
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: child,
                  secondChild: Center(
                    child: Container(color: Colors.black)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: const Duration(seconds: 1),
                          angle: 60 * (pi / 180),
                        ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            height: 48,
            child: Container(
              color: Colors.black,
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

class _AboutButton extends StatelessWidget {
  const _AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(
        Uri.parse('https://github.com/jaween/jerememe'),
        mode: LaunchMode.externalApplication,
      ),
      child: Text('Source on GitHub', style: TextStyle(color: Colors.white24)),
    );
  }
}
