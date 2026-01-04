import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kyf/app/routes/app_routes.dart';
import 'package:kyf/components/main_navigation.dart';
import 'package:kyf/features/auth/screens/complete_profile_screen.dart';
import 'package:kyf/features/auth/screens/login_screen.dart';
import 'package:kyf/features/auth/screens/otp_verification_screen.dart';
import 'package:kyf/features/splash/splash_screen.dart';

/// App Router Configuration
/// Central place for all route definitions and navigation logic

// Router Provider - Riverpod provider for accessing router throughout the app
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true, // Set to false in production
    
    // ============ Route Definitions ============
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ============ Auth Routes ============
      // Login with Phone Number
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // OTP Verification
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          // Get phone number and referenceId passed from login screen
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phoneNumber = extra['phoneNumber'] as String? ?? '';
          final referenceId = extra['referenceId'] as String? ?? '';
          return OtpVerificationScreen(
            phoneNumber: phoneNumber,
            referenceId: referenceId,
          );
        },
      ),

      // Complete Profile (for new users)
      GoRoute(
        path: AppRoutes.completeProfile,
        name: 'completeProfile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final token = extra['token'] as String? ?? '';
          final initialName = extra['fullName'] as String? ?? '';
          return CompleteProfileScreen(
            token: token,
            initialName: initialName,
          );
        },
      ),

      // ============ Main Routes ============
      // Home with Bottom Navigation
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigation(),
      ),
    ],

    // ============ Error Page ============
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Route: ${state.uri.path}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    // ============ Redirect Logic (Auth Guard) ============
    // Uncomment and customize when you have auth state
    // redirect: (context, state) {
    //   final isLoggedIn = ref.read(authProvider);
    //   final isOnAuthPages = state.matchedLocation == AppRoutes.login ||
    //                         state.matchedLocation == AppRoutes.verifyOtp;
    //   final isSplash = state.matchedLocation == AppRoutes.splash;
    //   
    //   // Allow splash screen always
    //   if (isSplash) return null;
    //   
    //   // If not logged in and not on auth pages, redirect to login
    //   if (!isLoggedIn && !isOnAuthPages) {
    //     return AppRoutes.login;
    //   }
    //   
    //   // If logged in and on auth pages, redirect to home
    //   if (isLoggedIn && isOnAuthPages) {
    //     return AppRoutes.home;
    //   }
    //   
    //   return null; // No redirect needed
    // },
  );
});

/// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  // Navigate to a route (replaces current stack)
  void goTo(String route) => GoRouter.of(this).go(route);
  
  // Push a new route (adds to stack)
  void pushTo(String route) => GoRouter.of(this).push(route);
  
  // Go back to previous route
  void goBack() => GoRouter.of(this).pop();
  
  // Check if can go back
  bool get canGoBack => GoRouter.of(this).canPop();
}
