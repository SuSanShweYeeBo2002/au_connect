import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulWidget {
  final User? receiver;
  final VoidCallback? onConversationUpdated;

  const ChatPage({Key? key, this.receiver, this.onConversationUpdated})
    : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  DateTime? _lastTypingNotification;
  String? _typingUserId;
  String? _currentUserId;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_onTypingChange);
  }

  Future<void> _initializeChat() async {
    await _loadCurrentUser();
    await _loadMessages();
    _setupSocket();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await AuthService.instance.getUserId();
    print('Loaded current user ID: "$userId"');
    setState(() {
      _currentUserId = userId;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setupSocket() async {
    print(
      '🔧 Setting up socket for chat with ${widget.receiver?.name} (${widget.receiver?.id})',
    );
    final socket = SocketService.instance;

    // Initialize socket and wait for connection
    await socket.initSocket();

    // Join a chat room if both current user and receiver are available
    if (_currentUserId != null && widget.receiver?.id != null) {
      // Create a consistent room ID for both users
      final roomId = _createChatRoomId(_currentUserId!, widget.receiver!.id);
      socket.joinChatRoom(roomId);
    } else {
      print(
        '⚠️ Cannot join room - currentUserId: $_currentUserId, receiverId: ${widget.receiver?.id}',
      );
    }

    // Add listeners after socket is initialized and room is joined
    socket.addMessageListener((data) {
      print('📨 ========= SOCKET MESSAGE RECEIVED =========');
      print('📥 Raw data: $data');

      try {
        final senderId = data['senderId'] ?? data['sender']?['_id'];
        final receiverId = data['receiverId'] ?? data['receiver']?['_id'];
        final content = data['content'];
        final currentUserId = _currentUserId;

        print('🔍 DETAILED MESSAGE ANALYSIS:');
        print('  📤 SenderId: $senderId');
        print('  📥 ReceiverId: $receiverId');
        print('  👤 CurrentUserId: $currentUserId');
        print('  🎯 Expected (other person): ${widget.receiver?.id}');
        print('  💬 Content: $content');
        print('  📱 Mounted: $mounted');

        // RULE 1: Only show messages where current user is the RECEIVER (not sender)
        // RULE 2: Only show messages FROM the other person in this chat
        // RULE 3: Don't process if we're currently sending a message
        final isMessageForMe = receiverId == currentUserId;
        final isFromOtherPerson = senderId == widget.receiver?.id;
        final shouldShow =
            mounted &&
            isMessageForMe &&
            isFromOtherPerson &&
            !_isSendingMessage;

        print('🤔 DECISION LOGIC:');
        print('  - Is mounted: $mounted');
        print(
          '  - Am I the receiver? $isMessageForMe ($receiverId == $currentUserId)',
        );
        print(
          '  - Is from other person? $isFromOtherPerson ($senderId == ${widget.receiver?.id})',
        );
        print('  - Currently sending? $_isSendingMessage');
        print('  - Should show message: $shouldShow');

        if (shouldShow) {
          print('✅ PROCESSING MESSAGE - I am the receiver!');
          final newMessage = Message.fromJson(data);

          // Simple duplicate check by ID
          final messageExists = _messages.any((msg) => msg.id == newMessage.id);

          print('🔄 DUPLICATE CHECK:');
          print('  - Message ID: ${newMessage.id}');
          print('  - Already exists: $messageExists');

          if (!messageExists) {
            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();
            print('✅ SUCCESS: Message added to UI - ${newMessage.content}');

            // Mark the new message as read since user is viewing the conversation
            _markMessagesAsRead();
          } else {
            print('⏭️  SKIPPED: Duplicate message - ${newMessage.content}');
          }
        } else {
          print('❌ REJECTED: Message not for me');
          print('  - Reason: I am NOT the receiver');
          print('  - SenderId: $senderId vs CurrentUser: $currentUserId');
          print('  - ReceiverId: $receiverId vs CurrentUser: $currentUserId');
        }
      } catch (e) {
        print('🚨 Error processing received message: $e');
        print('🚨 Message data: $data');
      }
    });

    socket.addTypingListener((userId) {
      print('⌨️ Chat page received typing from userId: $userId');
      try {
        if (mounted && userId.isNotEmpty && userId == widget.receiver?.id) {
          print('✅ Processing typing indicator from ${widget.receiver?.name}');
          setState(() {
            _typingUserId = userId;
          });
          // Clear typing indicator after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            if (mounted && _typingUserId == userId) {
              setState(() {
                _typingUserId = null;
              });
            }
          });
        } else {
          print(
            '❌ Typing not processed - userId: $userId, expected: ${widget.receiver?.id}',
          );
        }
      } catch (e) {
        print('🚨 Error processing typing indicator: $e');
      }
    });
  }

  void _onTypingChange() {
    final now = DateTime.now();
    if (_lastTypingNotification == null ||
        now.difference(_lastTypingNotification!) > Duration(seconds: 2)) {
      _lastTypingNotification = now;
      if (widget.receiver != null) {
        SocketService.instance.sendTypingNotification(widget.receiver!.id);
      }
    }
  }

  Future<void> _loadMessages() async {
    if (widget.receiver == null) return;

    setState(() => _isLoading = true);
    try {
      final messages = await ChatService.getConversation(widget.receiver!.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();

      // Mark messages as read when conversation is loaded
      _markMessagesAsRead();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load messages')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (widget.receiver == null) return;

    try {
      await ChatService.markMessageAsRead(widget.receiver!.id);
      print('Messages marked as read for user: ${widget.receiver!.name}');
    } catch (e) {
      print('Error marking messages as read: $e');
      // Don't show error to user for this background operation
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || widget.receiver == null || _isSendingMessage)
      return;

    setState(() {
      _isSendingMessage = true;
    });

    final messageText = text;
    _messageController.clear();

    // Create a temporary message for immediate display
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? 'current_user',
      receiverId: widget.receiver!.id,
      content: messageText,
      timestamp: DateTime.now(),
    );

    // Add the message to the local list immediately
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      // Send message using HTTP service
      final sentMessage = await ChatService.sendMessage(
        receiverId: widget.receiver!.id,
        content: messageText,
      );

      // Replace temporary message with actual message from server
      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
      });

      print('Message sent successfully: ${sentMessage.content}');

      // TEMPORARILY DISABLE socket sending - backend creates duplicate messages
      print(
        '🚫 Socket sending disabled - backend creates duplicates when both HTTP and Socket are used',
      );

      // TODO: Fix backend to handle both HTTP and Socket without creating duplicates
      // if (widget.receiver?.id != null) {
      //   SocketService.instance.sendMessage(widget.receiver!.id, messageText);
      //   print('✅ Socket message sent to: ${widget.receiver!.id}');
      // } else {
      //   print('⚠️ Cannot send socket message - receiver ID is null');
      // }
    } catch (e) {
      // Remove the temporary message if sending failed
      setState(() {
        _messages.removeWhere((msg) => msg.id == tempMessage.id);
      });

      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      // Reset the sending flag
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      // Show loading state
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleting message...')));

      // Call the delete API
      final success = await ChatService.deleteMessage(message.id);

      if (success) {
        // Remove message from local list
        setState(() {
          _messages.removeWhere((msg) => msg.id == message.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop && widget.onConversationUpdated != null) {
          widget.onConversationUpdated!();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF64B5F6),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Call the callback to refresh conversations list
              if (widget.onConversationUpdated != null) {
                widget.onConversationUpdated!();
              }
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.receiver?.name.substring(0, 1).toUpperCase() ?? 'A',
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiver?.name ?? 'New Chat',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_typingUserId == widget.receiver?.id)
                    Text(
                      'Typing...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: Icon(Icons.video_call), onPressed: () {}),
            IconButton(icon: Icon(Icons.call), onPressed: () {}),
            IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.senderId == _currentUserId;
                        return MessageBubble(
                          message: message,
                          isUser: isUser,
                          onDelete: isUser
                              ? () => _deleteMessage(message)
                              : null,
                        );
                      },
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -2),
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _handleSubmitted(_messageController.text);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create a consistent chat room ID for both users
  String _createChatRoomId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  void dispose() {
    print('🗑️ Disposing chat page - cleaning up socket listeners');

    // Leave the chat room
    if (_currentUserId != null && widget.receiver?.id != null) {
      final roomId = _createChatRoomId(_currentUserId!, widget.receiver!.id);
      SocketService.instance.leaveChatRoom(roomId);
    }

    _messageController.removeListener(_onTypingChange);
    _messageController.dispose();
    SocketService.instance.removeAllListeners();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  final VoidCallback? onDelete;

  const MessageBubble({
    required this.message,
    required this.isUser,
    this.onDelete,
  });

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                if (onDelete != null) {
                  onDelete!();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(backgroundColor: Color(0xFF64B5F6), child: Text('A')),
          SizedBox(width: 8),
          GestureDetector(
            onLongPress: isUser ? () => _showDeleteDialog(context) : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF64B5F6) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      if (isUser && onDelete != null) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteDialog(context),
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: isUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          if (isUser)
            CircleAvatar(backgroundColor: Color(0xFF64B5F6), child: Text('U')),
        ],
      ),
    );
  }

  // Helper method to format message timestamp to user-friendly format
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final messageDate = timestamp;

    // Check if the message is from today
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      // Show time only for today's messages
      final hour = messageDate.hour;
      final minute = messageDate.minute.toString().padLeft(2, '0');

      // Convert to 12-hour format
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } else {
      // Show date and time for older messages
      final month = messageDate.month.toString().padLeft(2, '0');
      final day = messageDate.day.toString().padLeft(2, '0');
      final hour = messageDate.hour;
      final minute = messageDate.minute.toString().padLeft(2, '0');

      String timeStr;
      if (hour == 0) {
        timeStr = '12:$minute AM';
      } else if (hour < 12) {
        timeStr = '$hour:$minute AM';
      } else if (hour == 12) {
        timeStr = '12:$minute PM';
      } else {
        timeStr = '${hour - 12}:$minute PM';
      }

      return '$month/$day $timeStr';
    }
  }
}
