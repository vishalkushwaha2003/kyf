import 'package:kyf/config/api_config.dart';
import 'package:kyf/services/api_service.dart';

/// User Service
/// Handles user-related API calls

class UserService {
  final ApiService _api = ApiService();

  /// Update user profile
  /// Updates fullName and DOB for the user
  Future<ApiResponse> updateProfile({
    required String token,
    required String fullName,
    required String dob,
  }) async {
    return await _api.patch(
      Endpoints.users.update,
      body: {
        'fullName': fullName,
        'dob': dob,
      },
      token: token,
    );
  }

  /// Get user profile
  Future<ApiResponse> getProfile({required String token}) async {
    return await _api.get(
      Endpoints.users.profile,
      token: token,
    );
  }
}
