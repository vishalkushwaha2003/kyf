import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyf/socket/socket_authentication.dart';
import 'package:kyf/socket/socket_constants.dart';
import 'package:kyf/socket/socket_manager.dart';

/// Upload State
enum UploadStatus { idle, preparing, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? message;
  final String? error;
  final String? uploadedUrl;

  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0,
    this.message,
    this.error,
    this.uploadedUrl,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? message,
    String? error,
    String? uploadedUrl,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
    );
  }
}

/// File Upload Service
/// Handles file uploads via socket with progress tracking

class FileUploadService {
  static final SocketManager _socketManager = SocketManager.instance;

  /// Valid image types
  static const List<String> validImageTypes = [
    'image/jpeg',
    'image/png',
    'image/jpg',
    'image/gif',
    'image/webp',
  ];

  /// Max file size (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Validate file
  static void validateFile(XFile file, int fileSize) {
    debugPrint('[FileUpload] Validating file: ${file.name}, size: $fileSize');

    final mimeType = file.mimeType ?? _getMimeType(file.name);
    
    if (!validImageTypes.contains(mimeType)) {
      throw Exception('Please upload a valid image file (JPEG, PNG, GIF, WebP)');
    }

    if (fileSize > maxFileSize) {
      throw Exception('File size should not exceed 5MB');
    }

    debugPrint('[FileUpload] File validation passed');
  }

  /// Get mime type from file extension
  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload avatar image
  static Future<UploadState> uploadAvatar({
    required XFile file,
    void Function(UploadState)? onProgress,
  }) async {
    final socket = _socketManager.getSocket(connectSocket: true);
    UploadState state = const UploadState(
      status: UploadStatus.preparing,
      progress: 0,
      message: 'Preparing upload...',
    );
    onProgress?.call(state);

    try {
      // Ensure socket is connected and authenticated
      if (!_socketManager.isConnected) {
        state = state.copyWith(
          message: 'Connecting to server...',
          progress: 5,
        );
        onProgress?.call(state);
        
        final authenticated = await SocketAuthentication.ensureAuthenticated();
        if (!authenticated) {
          throw Exception('Failed to authenticate socket');
        }
      }

      // Validate file
      final bytes = await file.readAsBytes();
      validateFile(file, bytes.length);

      state = state.copyWith(
        status: UploadStatus.uploading,
        progress: 10,
        message: 'Starting upload...',
      );
      onProgress?.call(state);

      // Setup response handlers
      final completer = Completer<UploadState>();
      Timer? timeoutTimer;
      Function()? cleanupStart;
      Function()? cleanupSuccess;
      Function()? cleanupError;
      Function()? cleanupProgress;

      void cleanup() {
        timeoutTimer?.cancel();
        cleanupStart?.call();
        cleanupSuccess?.call();
        cleanupError?.call();
        cleanupProgress?.call();
      }

      // Timeout handler
      timeoutTimer = Timer(const Duration(minutes: 5), () {
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(UploadState(
            status: UploadStatus.error,
            error: 'Upload timed out',
            progress: 0,
          ));
        }
      });

      // Upload start listener
      cleanupStart = () => socket.off(SocketConstants.file.uploadStart);
      socket.on(SocketConstants.file.uploadStart, (data) {
        debugPrint('[FileUpload] Upload started: $data');
        state = state.copyWith(progress: 20, message: 'Upload in progress...');
        onProgress?.call(state);
      });

      // Progress listener
      cleanupProgress = () => socket.off(SocketConstants.file.uploadProgress);
      socket.on(SocketConstants.file.uploadProgress, (data) {
        final progress = (data['progress'] as num?)?.toDouble() ?? 0;
        debugPrint('[FileUpload] Progress: $progress%');
        state = state.copyWith(
          progress: 20 + (progress * 0.7), // Scale to 20-90%
          message: 'Uploading... ${progress.toInt()}%',
        );
        onProgress?.call(state);
      });

      // Success listener
      cleanupSuccess = () => socket.off(SocketConstants.file.uploadSuccess);
      socket.on(SocketConstants.file.uploadSuccess, (response) {
        debugPrint('[FileUpload] Upload success: $response');
        cleanup();
        if (!completer.isCompleted) {
          final url = response['url'] ?? response['data']?['url'];
          completer.complete(UploadState(
            status: UploadStatus.success,
            progress: 100,
            message: 'Upload complete!',
            uploadedUrl: url?.toString(),
          ));
        }
      });

      // Error listener
      cleanupError = () => socket.off(SocketConstants.file.uploadError);
      socket.on(SocketConstants.file.uploadError, (error) {
        debugPrint('[FileUpload] Upload error: $error');
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(UploadState(
            status: UploadStatus.error,
            error: error['message']?.toString() ?? 'Upload failed',
            progress: 0,
          ));
        }
      });

      // Prepare upload data - send bytes as Uint8List for proper binary transfer
      final uploadData = {
        'file': Uint8List.fromList(bytes),  // Uint8List for proper binary
        'fileName': file.name,
        'fileType': file.mimeType ?? _getMimeType(file.name),
        'size': bytes.length,
        'type': 'avatar',
        'metadata': {
          'uploadType': 'cloudinary',
          'folder': 'avatars',
        },
      };

      // Debug socket state before emit
      debugPrint('[FileUpload] Socket connected: ${socket.connected}');
      debugPrint('[FileUpload] Socket ID: ${socket.id}');
      
      if (!socket.connected) {
        debugPrint('[FileUpload] Socket not connected! Trying to connect...');
        socket.connect();
        // Wait a bit for connection
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('[FileUpload] Socket connected after wait: ${socket.connected}');
      }

      // Also listen to generic response event
      Function()? cleanupResponse;
      cleanupResponse = () => socket.off(SocketConstants.file.uploadResponse);
      socket.on(SocketConstants.file.uploadResponse, (response) {
        debugPrint('[FileUpload] Upload response received: $response');
        cleanup();
        cleanupResponse?.call();
        if (!completer.isCompleted) {
          if (response['status'] == 'success') {
            final url = response['url'] ?? response['data']?['url'];
            completer.complete(UploadState(
              status: UploadStatus.success,
              progress: 100,
              message: 'Upload complete!',
              uploadedUrl: url?.toString(),
            ));
          } else {
            completer.complete(UploadState(
              status: UploadStatus.error,
              error: response['message']?.toString() ?? 'Upload failed',
              progress: 0,
            ));
          }
        }
      });

      debugPrint('[FileUpload] Emitting ${SocketConstants.file.upload} event with ${bytes.length} bytes');
      socket.emit(SocketConstants.file.upload, uploadData);
      
      state = state.copyWith(progress: 15, message: 'Sending file...');
      onProgress?.call(state);
      debugPrint('[FileUpload] Waiting for server response...');

      // Wait for response
      final result = await completer.future;
      cleanupResponse?.call();
      debugPrint('[FileUpload] Got response: ${result.status}');
      onProgress?.call(result);
      return result;

    } catch (e) {
      debugPrint('[FileUpload] Error: $e');
      final errorState = UploadState(
        status: UploadStatus.error,
        error: e.toString(),
        progress: 0,
      );
      onProgress?.call(errorState);
      return errorState;
    }
  }
}
