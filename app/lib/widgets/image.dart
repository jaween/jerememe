import 'package:flutter/material.dart';

Widget animatedCrossFadeFilledLayoutBuilder(
  Widget topChild,
  Key topChildKey,
  Widget bottomChild,
  Key bottomChildKey,
) {
  return Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned.fill(key: bottomChildKey, child: bottomChild),
      Positioned.fill(key: topChildKey, child: topChild),
    ],
  );
}
