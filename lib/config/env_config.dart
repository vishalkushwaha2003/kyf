import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration
/// Reads environment variables from .env file (like React/Vite)
/// 
/// Usage:
///   EnvConfig.apiUrl       // Returns API_URL from .env
///   EnvConfig.isProduction // Returns true if ENV=production

class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  // ============ Load .env file ============
  /// Call this in main.dart before runApp()
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _validateRequiredVars();
  }

  // ============ Validate required variables ============
  static void _validateRequiredVars() {
    final requiredVars = ['API_URL', 'API_VERSION'];
    
    for (final varName in requiredVars) {
      if (dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty) {
        throw Exception('Missing required environment variable: $varName');
      }
    }
  }

  // ============ Environment Variables ============
  
  /// API Base URL (e.g., http://localhost:3000)
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  
  /// API URL (e.g., http://localhost:5005)
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:5005';
  
  /// API Version (e.g., v1)
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  
  /// Environment (development | production)
  static String get environment => dotenv.env['ENV'] ?? 'development';
  
  /// Use HTTPS
  static bool get useHttps => dotenv.env['USE_HTTPS']?.toLowerCase() == 'true';

  // ============ Computed Properties ============
  
  /// Is production environment
  static bool get isProduction => environment == 'production';
  
  /// Is development environment  
  static bool get isDevelopment => environment == 'development';

  // ============ Timeouts (in seconds) ============
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // ============ App Configuration ============
  static const String appName = 'KYF';
  static const String appVersion = '1.0.0';
}
