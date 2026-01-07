/// Chat Models
/// Data models for chat functionality

enum MessageStatus { sending, sent, delivered, read }

class ChatUser {
  final String id;
  final String name;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final diff = now.difference(lastSeen!);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSeen!.day}/${lastSeen!.month}/${lastSeen!.year}';
  }

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? 'Unknown',
      photoUrl: json['photoUrl'] ?? json['photo']?['thumbnail_url'] ?? json['photo']?['url'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen']) : null,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String messageType;
  final DateTime createdAt;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.messageType = 'text',
    required this.createdAt,
    this.status = MessageStatus.sending,
    this.deliveredAt,
    this.readAt,
  });

  bool get isSent => status != MessageStatus.sending;
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isRead => status == MessageStatus.read;

  String get timeText {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse status - can be object or string
    MessageStatus status = MessageStatus.sent;
    DateTime? deliveredAt;
    DateTime? readAt;
    
    if (json['status'] is Map) {
      final statusMap = json['status'] as Map;
      if (statusMap['isRead'] == true) {
        status = MessageStatus.read;
      } else if (statusMap['deliveredAt'] != null) {
        status = MessageStatus.delivered;
      }
      // Parse deliveredAt and readAt from status map
      if (statusMap['deliveredAt'] != null) {
        deliveredAt = DateTime.tryParse(statusMap['deliveredAt'].toString());
      }
      if (statusMap['readAt'] != null) {
        readAt = DateTime.tryParse(statusMap['readAt'].toString());
      }
    } else if (json['status'] is String) {
      switch (json['status']) {
        case 'read':
          status = MessageStatus.read;
          break;
        case 'delivered':
          status = MessageStatus.delivered;
          break;
        case 'sent':
          status = MessageStatus.sent;
          break;
        default:
          status = MessageStatus.sent;
      }
    }

    // Parse timestamp - can be in different fields
    DateTime createdAt = DateTime.now();
    if (json['timestamp'] != null) {
      createdAt = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender']?['id']?.toString() ?? json['sender']?.toString() ?? '',
      text: json['content']?.toString() ?? json['text']?.toString() ?? json['message']?['text']?.toString() ?? '',
      messageType: json['type']?.toString() ?? json['messageType']?.toString() ?? 'text',
      createdAt: createdAt,
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  ChatMessage copyWith({
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      messageType: messageType,
      createdAt: createdAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class Chat {
  final String id;
  final ChatUser otherUser;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Find the other participant
    final participants = json['participants'] as List?;
    Map<String, dynamic>? otherUserData;
    
    if (participants != null) {
      for (final p in participants) {
        if (p['id'] != currentUserId && p['_id'] != currentUserId) {
          otherUserData = p;
          break;
        }
      }
    }
    
    otherUserData ??= json['otherUser'] as Map<String, dynamic>? ?? {};

    return Chat(
      id: json['chatId'] ?? json['id'] ?? json['_id'] ?? '',
      otherUser: ChatUser.fromJson(otherUserData!),
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
