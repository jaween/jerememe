import 'package:flutter/material.dart';

class ProportionalFontSizeBuilder extends StatelessWidget {
  final double baseWidth;
  final double baseFontSize;
  final double minFontSize;
  final Widget Function(BuildContext context, double fontSize) builder;

  const ProportionalFontSizeBuilder({
    super.key,
    this.baseWidth = 500,
    this.baseFontSize = 36,
    this.minFontSize = 10,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / baseWidth).clamp(0.0, double.infinity);
        final fontSize = (baseFontSize * scale).clamp(
          minFontSize,
          baseFontSize,
        );
        return builder(context, fontSize);
      },
    );
  }
}
