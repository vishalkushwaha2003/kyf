import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyf/app/routes/app_router.dart';
import 'package:kyf/constants/theme.dart';
import 'package:kyf/provider/themeProvider.dart';

/// Root application widget
/// Wraps the app with MaterialApp.router and provides theme configuration
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode from provider
    final themeMode = ref.watch(themeModeProvider);
    
    // Get router from provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KYF App',
      debugShowCheckedModeBanner: false,
      
      // Dynamic theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Router configuration (go_router)
      routerConfig: router,
    );
  }
}