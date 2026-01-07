import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kyf/models/chat_models.dart';
import 'package:kyf/socket/socket_authentication.dart';
import 'package:kyf/socket/socket_constants.dart';
import 'package:kyf/socket/socket_manager.dart';
import 'package:kyf/socket/socket_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Chat Socket Constants
class ChatEvents {
  ChatEvents._();
  
  // Outgoing events (matching frontend JS ChatService)
  static const String sendMessage = 'message';  // Backend expects 'message'
  static const String checkChat = 'chat:check';
  static const String createChat = 'chat:create';
  static const String joinChat = 'chat:join';
  static const String getHistory = 'chat:history';
  static const String typingStatus = 'typing:status';
  static const String deliveredAck = 'delivered-ack';
  static const String seenAck = 'seen-ack';
  
  // Incoming events (matching frontend JS ChatService)
  static const String newMessage = 'message';  // Backend sends 'message' for received messages too
  static const String sentAck = 'sent-ack';  // Backend sends 'sent-ack' for acknowledgment
  static const String messageError = 'message:error';
  static const String delivered = 'delivered';
  static const String seen = 'seen';
  static const String typingStatusReceived = 'typing:status';
  static const String systemMessage = 'system:message';
}

/// Chat Service
/// Handles chat socket communication

class ChatService {
  static final SocketManager _socketManager = SocketManager.instance;
  
  // Event callbacks
  Function(ChatMessage)? onMessageReceived;
  Function(String messageId, String chatId)? onMessageSent;
  Function(String messageId)? onMessageDelivered;
  Function(String messageId)? onMessageRead;
  Function(String chatId, bool isTyping)? onTypingStatus;
  Function(dynamic error)? onError;

  final Map<String, Function> _listeners = {};
  Timer? _typingTimer;

  /// Check if socket is connected
  bool get isConnected => _socketManager.isConnected;
  
  /// Track if listeners are already initialized
  bool _listenersInitialized = false;

  /// Initialize chat listeners
  void initializeListeners() {
    // Prevent duplicate listeners
    if (_listenersInitialized) {
      debugPrint('[ChatService] Listeners already initialized, skipping');
      return;
    }
    
    final socket = _socketManager.getSocket();
    
    // Debug: Log socket status
    debugPrint('[ChatService] Socket connected: ${socket.connected}');
    debugPrint('[ChatService] Socket ID: ${socket.id}');
    
    // Handler for parsing incoming messages
    void handleIncomingMessage(dynamic rawData) {
      debugPrint('[ChatService] Raw incoming data: $rawData');
      if (rawData == null || onMessageReceived == null) return;
      
      try {
        // The message might be wrapped in a 'data' field
        final data = rawData['data'] ?? rawData;
        final messageData = data['message'] ?? data;
        
        debugPrint('[ChatService] Extracted message data: $messageData');
        
        final chatMessage = ChatMessage(
          id: messageData['messageId']?.toString() ?? data['messageId']?.toString() ?? '',
          chatId: messageData['chatId']?.toString() ?? data['chatId']?.toString() ?? '',
          senderId: messageData['senderId']?.toString() ?? data['senderId']?.toString() ?? data['sender']?['id']?.toString() ?? '',
          text: messageData['text']?.toString() ?? messageData['content']?.toString() ?? '',
          messageType: messageData['messageType']?.toString() ?? messageData['type']?.toString() ?? 'text',
          createdAt: DateTime.now(),
          status: MessageStatus.sent,
        );
        debugPrint('[ChatService] Parsed message: "${chatMessage.text}" from ${chatMessage.senderId}');
        onMessageReceived!(chatMessage);
      } catch (e) {
        debugPrint('[ChatService] Error parsing message: $e');
      }
    }
    
    // Listen to 'message' event (main event)
    _addListener(socket, ChatEvents.newMessage, handleIncomingMessage);
    
    // Also listen to 'chat:new:message' event (from backend test code)
    _addListener(socket, 'chat:new:message', handleIncomingMessage);
    
    _listenersInitialized = true;

    // Message sent acknowledgment
    _addListener(socket, ChatEvents.sentAck, (data) {
      debugPrint('[ChatService] Message sent ack: $data');
      if (data != null && onMessageSent != null) {
        onMessageSent!(
          data['messageId']?.toString() ?? '',
          data['chatId']?.toString() ?? '',
        );
      }
    });

    // Message delivered
    _addListener(socket, ChatEvents.delivered, (data) {
      debugPrint('[ChatService] Message delivered: $data');
      if (data != null && onMessageDelivered != null) {
        onMessageDelivered!(data['messageId']?.toString() ?? '');
      }
    });

    // Message read
    _addListener(socket, ChatEvents.seen, (data) {
      debugPrint('[ChatService] Message read: $data');
      if (data != null && onMessageRead != null) {
        onMessageRead!(data['messageId']?.toString() ?? '');
      }
    });

    // Typing status
    _addListener(socket, ChatEvents.typingStatusReceived, (data) {
      if (data != null && onTypingStatus != null) {
        onTypingStatus!(
          data['chatId']?.toString() ?? '',
          data['status'] == true,
        );
      }
    });

    // Error
    _addListener(socket, ChatEvents.messageError, (error) {
      debugPrint('[ChatService] Error: $error');
      onError?.call(error);
    });
  }

  void _addListener(io.Socket socket, String event, Function(dynamic) handler) {
    socket.on(event, handler);
    _listeners[event] = handler;
    debugPrint('[ChatService] Listening to: $event');
  }

  /// Check for existing chat and get history
  /// senderId: current user's ID
  /// receiverId: other user's ID
  Future<Map<String, dynamic>?> checkChat(String senderId, String receiverId) async {
    try {
      // Ensure socket is authenticated first
      final isAuthenticated = await SocketAuthentication.ensureAuthenticated();
      if (!isAuthenticated) {
        debugPrint('[ChatService] Socket not authenticated! Cannot check chat.');
        return null;
      }
      
      final socket = _socketManager.getSocket();
      debugPrint('[ChatService] Socket connected: ${socket.connected}, ID: ${socket.id}');
      debugPrint('[ChatService] Checking chat between sender: $senderId and receiver: $receiverId');
      
      final response = await SocketUtils.emitWithAck(
        socket: socket,
        event: ChatEvents.checkChat,
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        timeout: const Duration(seconds: 10),
      );
      
      debugPrint('[ChatService] checkChat response: $response');
      
      if (response?['status'] == 'success') {
        if (response?['exists'] == true && response?['chat'] != null) {
          final chat = response!['chat'];
          final chatId = chat['chatId']?.toString();
          
          // Messages are directly in chat.messages
          final messages = chat['messages'] as List?;
          
          debugPrint('[ChatService] Found chatId: $chatId, messages: ${messages?.length ?? 0}');
          
          return {
            'chatId': chatId,
            'messages': messages ?? [],
            'exists': true,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ChatService] checkChat error: $e');
      return null;
    }
  }

  /// Get chat history
  Future<List<dynamic>> getHistory(String chatId) async {
    try {
      final socket = _socketManager.getSocket();
      final response = await SocketUtils.emitWithAck(
        socket: socket,
        event: ChatEvents.getHistory,
        data: {
          'chatId': chatId,
          'limit': 50,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        timeout: const Duration(seconds: 10),
      );
      
      debugPrint('[ChatService] getHistory response: $response');
      
      if (response?['status'] == 'success') {
        return response?['messages'] as List? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('[ChatService] getHistory error: $e');
      return [];
    }
  }

  /// Create new chat
  Future<String?> createChat(String receiverId) async {
    try {
      final socket = _socketManager.getSocket();
      final response = await SocketUtils.emitWithAck(
        socket: socket,
        event: ChatEvents.createChat,
        data: {
          'receiverId': receiverId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        timeout: const Duration(seconds: 10),
      );
      
      if (response?['status'] == 'success') {
        return response?['chatId'];
      }
      return null;
    } catch (e) {
      debugPrint('[ChatService] createChat error: $e');
      return null;
    }
  }

  /// Send message
  Future<Map<String, dynamic>?> sendMessage({
    String? chatId,
    required String receiverId,
    required String text,
    String messageType = 'text',
  }) async {
    try {
      // Ensure socket is authenticated first
      final isAuthenticated = await SocketAuthentication.ensureAuthenticated();
      if (!isAuthenticated) {
        throw Exception('Socket not authenticated');
      }
      
      final socket = _socketManager.getSocket();
      debugPrint('[ChatService] Sending message via socket: ${socket.id}');
      
      final payload = {
        if (chatId != null) 'chatId': chatId,
        'receiverId': receiverId,
        'text': text,
        'messageType': messageType,
        'chatType': 'userToUser',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await SocketUtils.emitWithAck(
        socket: socket,
        event: ChatEvents.sendMessage,
        data: payload,
        timeout: const Duration(seconds: 10),
      );

      if (response?['status'] == 'success' || response?['messageId'] != null) {
        return response;
      }
      throw Exception(response?['message'] ?? 'Failed to send message');
    } catch (e) {
      debugPrint('[ChatService] sendMessage error: $e');
      rethrow;
    }
  }

  /// Handle typing status
  void setTyping(String chatId, bool isTyping) {
    _typingTimer?.cancel();
    final socket = _socketManager.getSocket();


    void emitTyping(bool status) {
      socket.emit(ChatEvents.typingStatus, {
        'chatId': chatId,
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    if (isTyping) {
      emitTyping(true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        emitTyping(false);
      });
    } else {
      emitTyping(false);
    }
  }

  /// Mark message as delivered
  void markDelivered(String chatId, String messageId) {
    final socket = _socketManager.getSocket();
    socket.emit(ChatEvents.deliveredAck, {
      'chatId': chatId,
      'messageId': messageId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Mark message as read
  void markRead(String chatId, String messageId) {
    final socket = _socketManager.getSocket();
    socket.emit(ChatEvents.seenAck, {
      'chatId': chatId,
      'messageId': messageId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Cleanup listeners
  void dispose() {
    final socket = _socketManager.getSocket();
    _listeners.forEach((event, _) {
      socket.off(event);
    });
    _listeners.clear();
    _typingTimer?.cancel();
  }
}
