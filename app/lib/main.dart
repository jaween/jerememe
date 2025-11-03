import 'package:app/jerememe_app.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  const baseUrl = 'https://api.meme.tehpwnagefeed.online/v1';
  final apiService = ApiService(baseUrl: baseUrl);

  runApp(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(apiService)],
      child: const JerememeApp(),
    ),
  );
}
