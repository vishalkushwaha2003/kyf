import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

/// Application entry point
/// Wraps app with ProviderScope for Riverpod state management
void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope enables Riverpod throughout the app
    const ProviderScope(
      child: MyApp(),
    ),
  );
}