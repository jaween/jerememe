import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Custom transition page with a fade transition.
class TopLevelTransitionPage<T> extends CustomTransitionPage<T> {
  const TopLevelTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
         transitionsBuilder: _transitionsBuilder,
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
