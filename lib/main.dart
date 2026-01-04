import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyf/config/env_config.dart';
import 'app/app.dart';

/// Application entry point
/// Wraps app with ProviderScope for Riverpod state management
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await EnvConfig.load();

  runApp(
    // ProviderScope enables Riverpod throughout the app
    const ProviderScope(
      child: MyApp(),
    ),
  );
}