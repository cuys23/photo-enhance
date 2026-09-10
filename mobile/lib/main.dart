import 'package:flutter/material.dart';

import 'ai/company_provider.dart';
import 'ai/mock_provider.dart';
import 'ai/provider.dart';
import 'jobs/job_runner.dart';
import 'ui/home_screen.dart';

/// The single switch between the mock and the company API.
///
///   flutter run --dart-define=API_BASE_URL=https://api.example.com
///
/// With no base URL the app runs entirely on MockProvider, so the UI can be
/// built and demoed before the backend exists.
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

AiProvider buildProvider() =>
    _apiBaseUrl.isEmpty ? MockProvider() : CompanyApiProvider(baseUrl: _apiBaseUrl);

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final JobRunner _runner = JobRunner(buildProvider());

  @override
  void dispose() {
    _runner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Enhance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5652F),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(runner: _runner),
    );
  }
}
