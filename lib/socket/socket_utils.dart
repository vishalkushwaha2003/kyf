import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Retry Options for socket operations
class RetryOptions {
  final int maxRetries;
  final Duration delay;
  final bool exponential;
  final bool Function(dynamic error)? shouldRetry;
  final void Function(int attempt, dynamic error)? onRetry;

  const RetryOptions({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 1),
    this.exponential = true,
    this.shouldRetry,
    this.onRetry,
  });
}

/// Socket Utilities
/// Helper functions for socket operations with retry and timeout support

class SocketUtils {
  /// Emit event with acknowledgment and optional retry
  static Future<Map<String, dynamic>?> emitWithAck({
    required io.Socket socket,
    required String event,
    required Map<String, dynamic> data,
    Duration timeout = const Duration(seconds: 5),
    RetryOptions? retryOptions,
  }) async {
    Future<Map<String, dynamic>?> emitOnce() async {
      final completer = Completer<Map<String, dynamic>?>();
      Timer? timeoutTimer;

      try {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Event $event timed out after ${timeout.inSeconds}s'),
            );
          }
        });

        debugPrint('[SocketUtils] Emitting event: $event with data: $data');

        socket.emitWithAck(event, data, ack: (response) {
          timeoutTimer?.cancel();
          if (!completer.isCompleted) {
            debugPrint('[SocketUtils] Received ack for $event: $response');
            if (response is Map) {
              completer.complete(Map<String, dynamic>.from(response));
            } else {
              completer.complete({'data': response});
            }
          }
        });

        return await completer.future;
      } catch (e) {
        timeoutTimer?.cancel();
        rethrow;
      }
    }

    if (retryOptions != null) {
      return _withRetry(emitOnce, retryOptions);
    }

    return emitOnce();
  }

  /// Emit event without acknowledgment
  static void emit({
    required io.Socket socket,
    required String event,
    required Map<String, dynamic> data,
  }) {
    debugPrint('[SocketUtils] Emitting event: $event');
    socket.emit(event, data);
  }

  /// Listen to an event with optional transformation
  static Function() listen({
    required io.Socket socket,
    required String event,
    required void Function(dynamic data) handler,
    Map<String, dynamic> Function(dynamic data)? transform,
    bool Function(dynamic data)? filter,
    bool once = false,
  }) {
    wrappedHandler(dynamic data) {
      try {
        // Apply filter if provided
        if (filter != null && !filter(data)) {
          return;
        }

        // Transform data if provided
        final transformedData = transform != null ? transform(data) : data;
        handler(transformedData);
      } catch (e) {
        debugPrint('[SocketUtils] Error in event handler for $event: $e');
      }
    }

    if (once) {
      socket.once(event, wrappedHandler);
    } else {
      socket.on(event, wrappedHandler);
    }

    // Return cleanup function
    return () => socket.off(event, wrappedHandler);
  }

  /// Retry wrapper for async operations
  static Future<T> _withRetry<T>(
    Future<T> Function() operation,
    RetryOptions options,
  ) async {
    int attempt = 0;

    while (attempt < options.maxRetries) {
      try {
        if (attempt > 0) {
          debugPrint('[SocketUtils] Retry attempt ${attempt + 1} of ${options.maxRetries}');
        }
        return await operation();
      } catch (error) {
        attempt++;
        debugPrint('[SocketUtils] Error on attempt $attempt: $error');

        // Check if we should retry
        final shouldRetry = options.shouldRetry?.call(error) ?? true;
        
        if (attempt >= options.maxRetries || !shouldRetry) {
          debugPrint('[SocketUtils] Giving up after $attempt attempts');
          rethrow;
        }

        // Calculate wait time
        final waitTime = options.exponential
            ? options.delay * (1 << (attempt - 1))
            : options.delay;

        options.onRetry?.call(attempt, error);
        await Future.delayed(waitTime);
      }
    }

    throw Exception('Max retries exceeded');
  }
}
