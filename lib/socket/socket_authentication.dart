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
  static bool _isAuthenticated = false;
  
  /// Check if already authenticated
  static bool get isAuthenticated => _isAuthenticated && _socketManager.isConnected;

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
      
      // IMPORTANT: Wait for socket to actually connect before authenticating
      if (!socket.connected) {
        debugPrint('[SocketAuth] Waiting for socket connection...');
        final connected = await _waitForConnection(socket, timeout: const Duration(seconds: 10));
        if (!connected) {
          throw Exception('Socket connection timeout');
        }
        debugPrint('[SocketAuth] Socket connected, proceeding with authentication');
      }
      
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
        _isAuthenticated = true;
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

  /// Wait for socket connection with timeout
  static Future<bool> _waitForConnection(dynamic socket, {Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;
    Function(dynamic)? connectHandler;
    Function(dynamic)? errorHandler;

    try {
      // Set up timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          debugPrint('[SocketAuth] Connection timeout after ${timeout.inSeconds}s');
          completer.complete(false);
        }
      });

      // Listen for connect event
      connectHandler = (_) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          debugPrint('[SocketAuth] Socket connected!');
          completer.complete(true);
        }
      };

      // Listen for connection error
      errorHandler = (error) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          debugPrint('[SocketAuth] Connection error: $error');
          completer.complete(false);
        }
      };

      socket.on('connect', connectHandler);
      socket.on('connect_error', errorHandler);

      // Check if already connected
      if (socket.connected) {
        timeoutTimer.cancel();
        return true;
      }

      return await completer.future;
    } finally {
      // Cleanup listeners
      if (connectHandler != null) socket.off('connect', connectHandler);
      if (errorHandler != null) socket.off('connect_error', errorHandler);
    }
  }

  /// Ensure socket is authenticated
  static Future<bool> ensureAuthenticated() async {
    // Return early if already authenticated
    if (isAuthenticated) {
      debugPrint('[SocketAuth] Already authenticated, skipping');
      return true;
    }
    
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
