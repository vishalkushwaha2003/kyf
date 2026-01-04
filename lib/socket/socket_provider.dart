import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/socket/socket_authentication.dart';
import 'package:kyf/socket/socket_constants.dart';
import 'package:kyf/socket/socket_manager.dart';

/// Socket State
class SocketState {
  final bool isConnected;
  final bool isAuthenticated;
  final bool isConnecting;
  final String? error;

  const SocketState({
    this.isConnected = false,
    this.isAuthenticated = false,
    this.isConnecting = false,
    this.error,
  });

  SocketState copyWith({
    bool? isConnected,
    bool? isAuthenticated,
    bool? isConnecting,
    String? error,
  }) {
    return SocketState(
      isConnected: isConnected ?? this.isConnected,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
    );
  }
}

/// Socket Notifier
class SocketNotifier extends StateNotifier<SocketState> {
  final SocketManager _socketManager = SocketManager.instance;

  SocketNotifier() : super(const SocketState()) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    SocketManager.onConnectionChange = (connected) {
      state = state.copyWith(isConnected: connected, isConnecting: false);
    };

    SocketManager.onAuthenticationChange = (authenticated) {
      state = state.copyWith(isAuthenticated: authenticated);
    };
  }

  /// Connect and authenticate socket
  Future<bool> connect() async {
    if (state.isConnected && state.isAuthenticated) {
      debugPrint('[SocketProvider] Already connected and authenticated');
      return true;
    }

    state = state.copyWith(isConnecting: true, error: null);

    try {
      final storage = await StorageService.getInstance();
      final token = storage.getToken();

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isConnecting: false,
          error: 'No token available',
        );
        return false;
      }

      // Get socket and connect
      final socket = _socketManager.getSocket(connectSocket: true);

      // Wait for connection
      if (!socket.connected) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Authenticate
      final authenticated = await SocketAuthentication.ensureAuthenticated();
      
      state = state.copyWith(
        isConnected: socket.connected,
        isAuthenticated: authenticated,
        isConnecting: false,
      );

      return authenticated;
    } catch (e) {
      debugPrint('[SocketProvider] Connection error: $e');
      state = state.copyWith(
        isConnecting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Disconnect socket
  void disconnect() {
    _socketManager.disconnect();
    state = const SocketState();
  }

  /// Listen to socket events
  Function() on(String event, void Function(dynamic) handler) {
    _socketManager.on(event, handler);
    return () => _socketManager.off(event, handler);
  }

  /// Emit socket event
  void emit(String event, dynamic data, {Function? ack}) {
    _socketManager.emit(event, data, ack: ack);
  }

  /// Get the socket instance
  get socket => _socketManager.getSocket();

  @override
  void dispose() {
    _socketManager.dispose();
    super.dispose();
  }
}

/// Socket Provider
final socketProvider = StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier();
});

/// Helper to check if socket is ready
final isSocketReadyProvider = Provider<bool>((ref) {
  final state = ref.watch(socketProvider);
  return state.isConnected && state.isAuthenticated;
});
