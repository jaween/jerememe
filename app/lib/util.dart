import 'package:flutter/material.dart';

Future<void> showError({
  required BuildContext context,
  required String message,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Error'),
        actionsAlignment: MainAxisAlignment.center,
        content: Text(message),
        actions: [
          OutlinedButton(
            onPressed: Navigator.of(context).pop,
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
