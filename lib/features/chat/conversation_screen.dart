import 'package:flutter/material.dart';
import 'package:kyf/models/chat_models.dart';
import 'package:kyf/services/chat_service.dart';
import 'package:kyf/services/storage_service.dart';

/// Conversation Screen
/// Real-time chat with socket communication, message status, and date separators

class ConversationScreen extends StatefulWidget {
  final Chat chat;
  final String? currentUserId;

  const ConversationScreen({
    super.key,
    required this.chat,
    this.currentUserId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  
  late String _currentUserId;
  String? _chatId;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _otherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUserId ?? '';
    _chatId = widget.chat.id.isNotEmpty ? widget.chat.id : null;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    // Load current user ID from storage if not provided
    if (_currentUserId.isEmpty) {
      final storage = await StorageService.getInstance();
      if (storage.hasProfile()) {
        final profile = storage.getProfile();
        debugPrint('[Chat] Profile found: $profile');
        _currentUserId = profile?['_id']?.toString() ?? profile?['id']?.toString() ?? '';
        debugPrint('[Chat] Loaded current user ID from storage: $_currentUserId');
      }
    }
    
    if (_currentUserId.isEmpty) {
      debugPrint('[Chat] ERROR: Current user ID is empty!');
      setState(() => _isLoading = false);
      return;
    }
    
    // Setup chat service listeners FIRST
    _chatService.onMessageReceived = _onMessageReceived;
    _chatService.onMessageSent = _onMessageSent;
    _chatService.onMessageDelivered = _onMessageDelivered;
    _chatService.onMessageRead = _onMessageRead;
    _chatService.onTypingStatus = _onTypingStatus;
    _chatService.initializeListeners();

    // Check for existing chat and load history
    try {
      // Pass both senderId (current user) and receiverId (other user)
      final existingChat = await _chatService.checkChat(_currentUserId, widget.chat.otherUser.id);
      debugPrint('[Chat] Existing chat: $existingChat');
      
      if (existingChat != null) {
        _chatId = existingChat['chatId']?.toString();
        
        // Load message history - messages are in 'messages' field
        final messages = existingChat['messages'] as List?;
        if (messages != null && messages.isNotEmpty) {
          debugPrint('[Chat] Loading ${messages.length} messages');
          final loadedMessages = <ChatMessage>[];
          for (final m in messages) {
            try {
              loadedMessages.add(ChatMessage.fromJson(m as Map<String, dynamic>));
            } catch (e) {
              debugPrint('[Chat] Error parsing message: $e, data: $m');
            }
          }
          _messages = loadedMessages;
          debugPrint('[Chat] Loaded ${_messages.length} messages successfully');
        }
      }
    } catch (e) {
      debugPrint('[Chat] Error loading chat: $e');
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _onMessageReceived(ChatMessage message) {
    debugPrint('[Chat] Received message: ${message.text} from ${message.senderId}');
    
    // Check if this message is for this chat (either by chatId or by sender)
    final isForThisChat = message.chatId == _chatId || 
                          message.senderId == widget.chat.otherUser.id ||
                          _chatId == null;
    
    if (isForThisChat && message.senderId != _currentUserId) {
      setState(() {
        // Avoid duplicate messages
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          if (_chatId == null || _chatId!.isEmpty) _chatId = message.chatId;
        }
      });
      _scrollToBottom();
      // Mark as read
      if (_chatId != null && _chatId!.isNotEmpty) {
        _chatService.markRead(_chatId!, message.id);
      }
    }
  }

  void _onMessageSent(String messageId, String chatId) {
    setState(() {
      if (_chatId == null) _chatId = chatId;
      // Update message status to sent
      final index = _messages.indexWhere((m) => m.id == messageId || m.status == MessageStatus.sending);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: MessageStatus.sent);
      }
    });
  }

  void _onMessageDelivered(String messageId) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: MessageStatus.delivered);
      }
    });
  }

  void _onMessageRead(String messageId) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: MessageStatus.read);
      }
    });
  }

  void _onTypingStatus(String chatId, bool isTyping) {
    if (chatId == _chatId) {
      setState(() => _otherUserTyping = isTyping);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add message locally with sending status
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessage(
      id: tempId,
      chatId: _chatId ?? '',
      senderId: _currentUserId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(message);
      _isTyping = false;
    });

    _messageController.clear();
    _scrollToBottom();
    _chatService.setTyping(_chatId ?? '', false);

    // Send via socket
    try {
      final response = await _chatService.sendMessage(
        chatId: _chatId,
        receiverId: widget.chat.otherUser.id,
        text: text,
      );

      debugPrint('[Chat] Send response: $response');

      if (response != null && response['status'] == 'success') {
        final messageId = response['messageId']?.toString() ?? tempId;
        final chatId = response['chatId']?.toString() ?? _chatId;
        
        setState(() {
          // Update chat ID if this was first message
          if (_chatId == null || _chatId!.isEmpty) {
            _chatId = chatId;
          }
          
          // Update message status to sent and update the real ID
          final index = _messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: messageId,
              chatId: chatId ?? '',
              senderId: _currentUserId,
              text: text,
              createdAt: _messages[index].createdAt,
              status: MessageStatus.sent,
            );
          }
        });
        debugPrint('[Chat] Message updated to sent status');
      } else {
        // Mark as failed (show error icon)
        debugPrint('[Chat] Message send failed');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Could add error status here to show failed icon
    }
  }

  void _onTyping(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTyping(_chatId ?? widget.chat.otherUser.id, true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _chatService.setTyping(_chatId ?? widget.chat.otherUser.id, false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.chat.otherUser;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.initials,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _otherUserTyping ? 'typing...' : user.lastSeenText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _otherUserTyping || user.isOnline
                          ? Colors.green
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          final showDateHeader = _shouldShowDateHeader(index);
                          
                          return Column(
                            children: [
                              if (showDateHeader)
                                _DateHeader(date: message.createdAt),
                              _MessageBubble(
                                message: message,
                                isMe: isMe,
                                showTail: _shouldShowTail(index),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hi to ${widget.chat.otherUser.name}!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    final current = _messages[index].createdAt;
    final previous = _messages[index - 1].createdAt;
    return !_isSameDay(current, previous);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _shouldShowTail(int index) {
    if (index == _messages.length - 1) return true;
    final current = _messages[index];
    final next = _messages[index + 1];
    return current.senderId != next.senderId;
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: _onTyping,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date Header Widget
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _formatDate(date),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}

/// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTail;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 2,
          bottom: showTail ? 8 : 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe || !showTail ? 18 : 4),
            bottomRight: Radius.circular(!isMe || !showTail ? 18 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMe
                        ? theme.colorScheme.onPrimary.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIcon(
                    status: message.status,
                    isMe: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Message Status Icon
class _MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final bool isMe;

  const _MessageStatusIcon({
    required this.status,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMe
        ? theme.colorScheme.onPrimary.withOpacity(0.7)
        : theme.colorScheme.onSurface.withOpacity(0.5);

    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time_rounded, size: 14, color: color);
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 14, color: color);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: color);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.lightBlueAccent);
    }
  }
}
