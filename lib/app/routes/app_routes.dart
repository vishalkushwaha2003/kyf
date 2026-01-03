/// App Routes - Contains all route path constants
/// This file defines route names as constants for type-safety and reusability

class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // ============ Auth Routes ============
  static const String splash = '/splash';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';

  // ============ Main Routes ============
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // ============ Feature Routes ============
  static const String notifications = '/notifications';
  
  // Dynamic routes with parameters
  static String userProfile(String userId) => '/profile/$userId';
}
