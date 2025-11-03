import 'package:flutter/material.dart';

Future<void> showError({
  required BuildContext context,
  required String message,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(title: Text('Error'), content: Text(message));
    },
  );
}
