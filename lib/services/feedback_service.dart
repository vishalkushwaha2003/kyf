import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kyf/config/api_config.dart';
import 'package:kyf/services/api_service.dart';
import 'package:kyf/config/env_config.dart';

/// Feedback Service
/// Handles bug/feedback submission API calls

class FeedbackService {
  final ApiService _api = ApiService();

  /// Submit bug feedback
  /// Pass screenWidth and screenHeight from MediaQuery for resolution
  Future<ApiResponse> submitFeedback({
    required String token,
    required String message,
    required String bugType,
    String? customBugType,
    String severity = 'Medium',
    String? stepsToReproduce,
    List<String>? attachmentUrls,
    double? screenWidth,
    double? screenHeight,
  }) async {
    // Gather system information automatically
    final systemInfo = _getSystemInfo(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    // Get location from IP (non-blocking, fails silently)
    final location = await _getLocationFromIP();

    final body = {
      'message': message,
      'bugType': bugType,
      if (customBugType != null) 'customBugType': customBugType,
      'severity': severity,
      if (stepsToReproduce != null) 'stepsToReproduce': stepsToReproduce,
      if (attachmentUrls != null && attachmentUrls.isNotEmpty)
        'attachmentUrls': attachmentUrls,
      ...systemInfo,
      if (location != null) 'location': location,
    };

    return await _api.post(
      Endpoints.feedback.submit,
      body: body,
      token: token,
    );
  }

  /// Get location information from IP using ip-api.com (free, no API key required)
  Future<Map<String, dynamic>?> _getLocationFromIP() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=status,city,country,regionName,query,lat,lon'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'city': data['city'],
            'country': data['country'],
            'region': data['regionName'],
            'ip': data['query'],
            'latitude': data['lat']?.toString(),
            'longitude': data['lon']?.toString(),
          };
        }
      }
    } catch (e) {
      // Silently fail - location is optional
      debugPrint('Failed to get location from IP: $e');
    }
    return null;
  }

  /// Get system information for bug report
  Map<String, dynamic> _getSystemInfo({
    double? screenWidth,
    double? screenHeight,
  }) {
    // Get device/browser info
    String browserInfo;
    if (Platform.isAndroid) {
      browserInfo = 'Android App';
    } else if (Platform.isIOS) {
      browserInfo = 'iOS App';
    } else if (Platform.isMacOS) {
      browserInfo = 'macOS App';
    } else if (Platform.isWindows) {
      browserInfo = 'Windows App';
    } else if (Platform.isLinux) {
      browserInfo = 'Linux App';
    } else {
      browserInfo = 'Flutter App';
    }

    // Get OS info
    final osInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

    // Get screen resolution
    String? screenResolution;
    if (screenWidth != null && screenHeight != null) {
      screenResolution = '${screenWidth.toInt()}x${screenHeight.toInt()}';
    }

    return {
      'browserInfo': browserInfo,
      'osInfo': osInfo,
      if (screenResolution != null) 'screenResolution': screenResolution,
      'appVersion': EnvConfig.appVersion,
    };
  }

  /// Get user's feedback history
  Future<ApiResponse> getMyFeedback({required String token}) async {
    return await _api.get(
      Endpoints.feedback.list,
      token: token,
    );
  }
}
