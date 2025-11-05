import 'package:app/create_page.dart';
import 'package:app/error_page.dart';
import 'package:app/home_page.dart';
import 'package:app/result_page.dart';
import 'package:app/services/models/meme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JerememeApp extends StatelessWidget {
  const JerememeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouterBuilder(
      navigatorObservers: [],
      builder: (context, router) {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        );
        return MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(
            colorScheme: colorScheme,
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RouterBuilder extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const _RouterBuilder({
    super.key,
    this.navigatorObservers = const [],
    required this.builder,
  });

  @override
  State<_RouterBuilder> createState() => _RouterBuilderState();
}

class _RouterBuilderState extends State<_RouterBuilder> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _initRouter(initialLocation: '/');
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _router);
  }

  GoRouter _initRouter({required String initialLocation}) {
    return GoRouter(
      debugLogDiagnostics: kDebugMode,
      observers: widget.navigatorObservers,
      initialLocation: initialLocation,
      overridePlatformDefaultLocation: true,

      errorBuilder: (context, state) => const ErrorPage(),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) {
            return SelectionArea(child: HomePage());
          },
          routes: [
            GoRoute(
              path: 'create/:mediaId/:frame',
              name: 'create',
              builder: (context, state) {
                final mediaId = state.pathParameters['mediaId'] as String;
                final frameString = state.pathParameters['frame'] as String;
                final frame = int.tryParse(frameString) ?? 0;
                return SelectionArea(
                  child: CreatePage(mediaId: mediaId, frameIndex: frame),
                );
              },
              routes: [
                GoRoute(
                  path: 'meme',
                  name: 'result',
                  builder: (context, state) {
                    final meme = state.extra as Meme?;
                    if (meme == null) {
                      throw 'Missing meme';
                    }
                    return SelectionArea(child: ResultPage(meme: meme));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
