import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/socket/socket_constants.dart';
import 'package:kyf/socket/socket_manager.dart';
import 'package:kyf/socket/socket_utils.dart';

/// Socket Authentication
/// Handles socket authentication, token refresh, and retry logic

class SocketAuthentication {
  static final SocketManager _socketManager = SocketManager.instance;

  /// Authenticate the socket with the current access token
  static Future<Map<String, dynamic>?> authenticate() async {
    if (_socketManager.isAuthenticating) {
      debugPrint('[SocketAuth] Already authenticating, waiting...');
      // Wait for ongoing authentication
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_socketManager.isAuthenticating) {
          return {'status': SocketConstants.status.authenticated};
        }
      }
      throw Exception('Authentication timeout');
    }

    try {
      _socketManager.isAuthenticating = true;
      final socket = _socketManager.getSocket(connectSocket: true);
      final storage = await StorageService.getInstance();
      final token = storage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      debugPrint('[SocketAuth] Authenticating with token...');

      final response = await SocketUtils.emitWithAck(
        socket: socket,
        event: SocketConstants.auth.authenticate,
        data: {'accessToken': token},
        timeout: const Duration(seconds: 30),
        retryOptions: RetryOptions(
          maxRetries: 3,
          delay: const Duration(seconds: 1),
          exponential: true,
          shouldRetry: (error) {
            // Don't retry for token expired or unexpected error
            final errorMsg = error.toString().toLowerCase();
            return !errorMsg.contains('token_expired') &&
                   !errorMsg.contains('unexpected_error');
          },
        ),
      );

      debugPrint('[SocketAuth] Authentication response: $response');

      if (response != null && response['status'] == SocketConstants.status.authenticated) {
        SocketManager.onAuthenticationChange?.call(true);
        debugPrint('[SocketAuth] Socket authenticated successfully!');
        return response;
      } else {
        throw Exception(response?['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      debugPrint('[SocketAuth] Authentication error: $e');
      SocketManager.onAuthenticationChange?.call(false);
      rethrow;
    } finally {
      _socketManager.isAuthenticating = false;
    }
  }

  /// Ensure socket is authenticated
  static Future<bool> ensureAuthenticated() async {
    if (_socketManager.isAuthenticating) {
      // Wait for ongoing authentication
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_socketManager.isAuthenticating && _socketManager.isConnected) {
          return true;
        }
      }
      throw Exception('Timed out waiting for authentication');
    }

    final storage = await StorageService.getInstance();
    final token = storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await authenticate();
      return response?['status'] == SocketConstants.status.authenticated;
    } catch (e) {
      debugPrint('[SocketAuth] ensureAuthenticated error: $e');
      return false;
    }
  }

  /// Disconnect and re-authenticate
  static Future<bool> reauthenticate() async {
    debugPrint('[SocketAuth] Re-authenticating...');
    _socketManager.disconnect();
    await Future.delayed(const Duration(milliseconds: 200));
    return ensureAuthenticated();
  }
}
