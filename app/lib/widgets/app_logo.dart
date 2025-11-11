import 'package:app/widgets/proportional_font_size_builder.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: ProportionalFontSizeBuilder(
        baseFontSize: 48,
        builder: (context, fontSize) {
          return Text(
            'JEREMEME',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Lithos', fontSize: fontSize),
          );
        },
      ),
    );
  }
}
