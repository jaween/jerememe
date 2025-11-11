import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('sry 404 page liek not found n stuf'),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.goNamed('home'),
              child: Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
