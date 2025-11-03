import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Page not found'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.goNamed('init'),
              child: Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
