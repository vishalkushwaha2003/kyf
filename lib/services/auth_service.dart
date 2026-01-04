import 'package:kyf/config/api_config.dart';
import 'package:kyf/services/api_service.dart';

/// Auth Service
/// Handles authentication-related API calls

class AuthService {
  final ApiService _api = ApiService();

  /// Generate OTP
  /// Sends OTP to the provided phone number
  Future<ApiResponse> generateOtp({required String phoneNumber}) async {
    return await _api.post(
      Endpoints.auth.generateOtp,
      body: {
        'mobNum': phoneNumber,
        'isTesting': true,
      },
    );
  }

  /// Verify OTP
  /// Verifies the OTP and returns auth tokens
  Future<ApiResponse> verifyOtp({
    required String referenceId,
    required String phoneNumber,
    required String otp,
  }) async {
    return await _api.post(
      Endpoints.auth.verifyOtp,
      body: {
        'referenceId': referenceId,
        'mobNum': phoneNumber,
        'otp': otp,
      },
    );
  }

  /// Login
  Future<ApiResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    return await _api.post(
      Endpoints.auth.login,
      body: {
        'phone': phoneNumber,
        'password': password,
      },
    );
  }

  /// Signup
  Future<ApiResponse> signup({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    return await _api.post(
      Endpoints.auth.signup,
      body: {
        'phone': phoneNumber,
        'name': name,
        'email': email,
      },
    );
  }

  /// Refresh Token
  Future<ApiResponse> refreshToken({required String refreshToken}) async {
    return await _api.post(
      Endpoints.auth.refreshToken,
      body: {
        'refreshToken': refreshToken,
      },
    );
  }
}
