import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:kyf/config/env_config.dart';
import 'package:kyf/socket/socket_constants.dart';

/// SocketManager Singleton
/// Encapsulates all socket logic (connect, disconnect, authenticate, event listeners)
/// Thread-safe singleton pattern for Flutter

class SocketManager {
  static SocketManager? _instance;
  static io.Socket? _socket;
  static bool _isAuthenticating = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Connection state callbacks
  static Function(bool)? onConnectionChange;
  static Function(bool)? onAuthenticationChange;

  SocketManager._();

  static SocketManager get instance {
    _instance ??= SocketManager._();
    return _instance!;
  }

  /// Get or create the socket instance
  io.Socket getSocket({bool testSocket = false, bool connectSocket = false}) {
    if (_socket != null) {
      if (connectSocket && !_socket!.connected && !_isAuthenticating) {
        debugPrint('[SocketManager] Connecting existing socket...');
        _socket!.connect();
        onConnectionChange?.call(true);
      }
      return _socket!;
    }

    final serverUrl = EnvConfig.apiUrl;
    debugPrint('[SocketManager] Creating new socket to: $serverUrl');

    final options = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(3)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .setTimeout(10000)
        .build();

    if (testSocket) {
      options['query'] = {
        'testMode': 'true',
        'userId': '123',
        'phoneNumber': '1234567890',
      };
    }

    _socket = io.io(serverUrl, options);
    _setupEventListeners();

    if (connectSocket) {
      debugPrint('[SocketManager] Connecting new socket...');
      _socket!.connect();
      onConnectionChange?.call(true);
    }

    return _socket!;
  }

  /// Setup default event listeners
  void _setupEventListeners() {
    _socket!.on(SocketConstants.auth.connect, (_) {
      debugPrint('[SocketManager] Socket connected');
      _reconnectAttempts = 0;
      onConnectionChange?.call(true);
    });

    _socket!.on(SocketConstants.auth.disconnect, (_) {
      debugPrint('[SocketManager] Socket disconnected');
      onConnectionChange?.call(false);
      onAuthenticationChange?.call(false);
      _isAuthenticating = false;
    });

    _socket!.on(SocketConstants.auth.connectError, (error) {
      debugPrint('[SocketManager] Connection error: $error');
      _reconnectAttempts++;
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        debugPrint('[SocketManager] Max reconnection attempts reached');
      }
    });
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// Check if currently authenticating
  bool get isAuthenticating => _isAuthenticating;
  
  /// Set authenticating state
  set isAuthenticating(bool value) => _isAuthenticating = value;

  /// Disconnect the socket
  void disconnect() {
    if (_socket?.connected ?? false) {
      debugPrint('[SocketManager] Disconnecting socket...');
      _socket!.disconnect();
      _isAuthenticating = false;
      onConnectionChange?.call(false);
      onAuthenticationChange?.call(false);
    }
  }

  /// Add event listener
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove event listener
  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  /// Emit event with optional acknowledgment
  void emit(String event, dynamic data, {Function? ack}) {
    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  /// Dispose and cleanup
  void dispose() {
    disconnect();
    _socket?.dispose();
    _socket = null;
    _instance = null;
  }
}
