import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kyf/config/env_config.dart';

/// API Service
/// Handles all HTTP requests to the backend

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = EnvConfig.apiUrl;

  // Headers
  Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ Generic HTTP Methods ============

  /// GET Request
  Future<ApiResponse> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(uri, headers: _getHeaders(token: token))
          .timeout(Duration(seconds: EnvConfig.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// POST Request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _getHeaders(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: EnvConfig.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// PATCH Request
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: EnvConfig.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// DELETE Request
  Future<ApiResponse> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: _getHeaders(token: token))
          .timeout(Duration(seconds: EnvConfig.connectionTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Handle Response
  ApiResponse _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        data: body,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse(
        success: false,
        message: body['message'] ?? 'Something went wrong',
        statusCode: response.statusCode,
        data: body,
      );
    }
  }
}

/// API Response Model
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}
