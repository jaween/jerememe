import 'package:app/create_page.dart';
import 'package:app/error_page.dart';
import 'package:app/home_page.dart';
import 'package:app/services/api_service.dart';
import 'package:app/transition.dart';
import 'package:app/viewer_page.dart';
import 'package:app/widgets/app_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const pwnageRed = Color.fromRGBO(0x99, 0x01, 0x00, 1.0);
const offBlack = Color.fromRGBO(0x06, 0x06, 0x06, 1.0);

class JerememeApp extends StatelessWidget {
  final String? initialLocation;

  const JerememeApp({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return _RouterBuilder(
      initialLocation: initialLocation,
      navigatorObservers: [],
      builder: (context, router) {
        return MaterialApp.router(routerConfig: router, theme: _buildTheme());
      },
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: pwnageRed,
      primary: pwnageRed,
      brightness: Brightness.dark,
    );
    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: offBlack,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        width: 500,
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white),
          borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white),
          borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
        ),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.rubikTextTheme(
        baseTheme.textTheme,
      ).apply(bodyColor: Colors.white),
    );
  }
}

class _RouterBuilder extends StatefulWidget {
  final String? initialLocation;
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const _RouterBuilder({
    super.key,
    this.initialLocation,
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
    _router = _initRouter(initialLocation: widget.initialLocation ?? '/');
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
        ShellRoute(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              pageBuilder: (context, state) {
                return TopLevelTransitionPage(
                  child: SelectionArea(child: HomePage()),
                );
              },
              routes: [
                GoRoute(
                  path: 'create/:mediaId/:frame',
                  name: 'create',
                  pageBuilder: (context, state) {
                    final mediaId = state.pathParameters['mediaId'] as String;
                    final frameString = state.pathParameters['frame'] as String;
                    final frame = int.tryParse(frameString) ?? 0;
                    return TopLevelTransitionPage(
                      child: SelectionArea(
                        child: CreatePage(mediaId: mediaId, frameIndex: frame),
                      ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/m/:id',
              name: 'viewer',
              pageBuilder: (context, state) {
                return TopLevelTransitionPage(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final api = ref.read(apiServiceProvider);
                      final pathWithLeadingSlash = state.uri.path;
                      final memeKey = pathWithLeadingSlash.substring(1);
                      final id = memeKey.substring(2);
                      final url = api.urlForViewingKey(memeKey);
                      return SelectionArea(
                        child: ViewerPage(id: id, url: url),
                      );
                    },
                  ),
                );
              },
            ),
          ],
          builder: (context, state, child) {
            return _Shell(child: child);
          },
        ),
      ],
    );
  }
}

class _Shell extends StatefulWidget {
  final Widget child;

  const _Shell({super.key, required this.child});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  bool _canPop = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GoRouter.of(context).routerDelegate.removeListener(_onRoutesUpdated);
    GoRouter.of(context).routerDelegate.addListener(_onRoutesUpdated);
  }

  @override
  void dispose() {
    GoRouter.of(context).routerDelegate.removeListener(_onRoutesUpdated);
    super.dispose();
  }

  void _onRoutesUpdated() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final canPop = GoRouter.of(context).canPop();
    setState(() => _canPop = canPop);
  }

  @override
  Widget build(BuildContext context) {
    final hasSpace = MediaQuery.widthOf(context) >= 800 || !_canPop;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_canPop)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(
                            onPressed: () {
                              // Extra check as we waited a frame earlier
                              if (GoRouter.of(context).canPop()) {
                                context.pop();
                              }
                            },
                          ),
                        ),
                      Expanded(
                        child: Center(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => context.goNamed('home'),
                              child: AppLogo(),
                            ),
                          ),
                        ),
                      ),
                      // Used to balance logo (stays vertically centered)
                      if (_canPop)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ExcludeFocus(
                            child: Opacity(
                              opacity: 0,
                              child: IgnorePointer(
                                child: BackButton(onPressed: null),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
