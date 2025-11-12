import 'package:app/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              Align(alignment: Alignment.topCenter, child: AppLogo()),
              Center(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      Text(
                        'sry 404 page liek not found n stuf',
                        textAlign: TextAlign.center,
                        style: TextTheme.of(context).titleLarge,
                      ),
                      const SizedBox(height: 64),
                      FilledButton(
                        onPressed: () => context.goNamed('home'),
                        child: Text('Go Back Home'),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
