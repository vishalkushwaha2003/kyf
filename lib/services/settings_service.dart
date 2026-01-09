import 'package:kyf/config/api_config.dart';
import 'package:kyf/services/api_service.dart';

/// Settings Service
/// Handles all settings-related API calls

class SettingsService {
  final ApiService _api = ApiService();

  /// Initialize user settings (creates default settings if none exist)
  Future<ApiResponse> initializeSettings({required String token}) async {
    return await _api.post(
      Endpoints.settings.initialize,
      token: token,
    );
  }

  /// Fetch all user settings
  Future<ApiResponse> fetchSettings({required String token}) async {
    return await _api.get(
      Endpoints.settings.fetch,
      token: token,
    );
  }

  /// Update theme settings
  Future<ApiResponse> updateTheme({
    required String token,
    required Map<String, dynamic> themeData,
  }) async {
    return await _api.patch(
      Endpoints.settings.theme,
      body: themeData,
      token: token,
    );
  }

  /// Update notification settings
  Future<ApiResponse> updateNotifications({
    required String token,
    required Map<String, dynamic> notificationData,
  }) async {
    return await _api.patch(
      Endpoints.settings.notifications,
      body: notificationData,
      token: token,
    );
  }

  /// Update privacy settings
  Future<ApiResponse> updatePrivacy({
    required String token,
    required Map<String, dynamic> privacyData,
  }) async {
    return await _api.patch(
      Endpoints.settings.privacy,
      body: privacyData,
      token: token,
    );
  }

  /// Update preferences settings
  Future<ApiResponse> updatePreferences({
    required String token,
    required Map<String, dynamic> preferencesData,
  }) async {
    return await _api.patch(
      Endpoints.settings.preferences,
      body: preferencesData,
      token: token,
    );
  }

  /// Update layout settings
  Future<ApiResponse> updateLayout({
    required String token,
    required Map<String, dynamic> layoutData,
  }) async {
    return await _api.patch(
      Endpoints.settings.layout,
      body: layoutData,
      token: token,
    );
  }

  /// Update accessibility settings
  Future<ApiResponse> updateAccessibility({
    required String token,
    required Map<String, dynamic> accessibilityData,
  }) async {
    return await _api.patch(
      Endpoints.settings.accessibility,
      body: accessibilityData,
      token: token,
    );
  }
}
