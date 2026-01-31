import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  final String _serverUrl = 'https://auconnectapi-production.up.railway.app';
  String? _pendingRoomId;

  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  Future<void> initSocket() async {
    if (_socket?.connected ?? false) {
      print('Socket already connected');
      return;
    }

    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      print('No auth token available for socket connection');
      return;
    }

    final userId = await AuthService.instance.getUserId();
    print(
      'Initializing socket with token: ${token.substring(0, 20)}... for user: $userId',
    );

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token, 'userId': userId},
      'timeout': 10000,
    });

    // Use await to ensure connection is established
    _socket!.connect();
    _setupSocketListeners();

    // Wait a bit for connection to establish
    await Future.delayed(Duration(milliseconds: 500));
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('✅ Socket connected successfully to $_serverUrl');

      // Join pending room if there is one
      if (_pendingRoomId != null) {
        print('🏠 Joining pending room: $_pendingRoomId');
        _socket?.emit('join_room', {'roomId': _pendingRoomId});
        _pendingRoomId = null;
      }
    });

    _socket?.onDisconnect((reason) {
      print('❌ Socket disconnected. Reason: $reason');
    });

    _socket?.onError((error) {
      print('🚨 Socket error: $error');
    });

    _socket?.onConnectError((error) {
      print('🚨 Socket connection error: $error');
    });

    // Listen for message events to debug
    _socket?.on('message_sent', (data) {
      print('📤 Message sent confirmation: $data');
    });

    // Remove the debug listener - will be handled by addMessageListener

    _socket?.on('user_typing', (data) {
      print('⌨️ User typing: $data');
    });
  }

  void addMessageListener(Function(Map<String, dynamic>) onMessageReceived) {
    print('🔗 Adding message listener');

    // Ensure socket is connected before adding listener
    if (!isConnected) {
      print('⚠️ Socket not connected, initializing first...');
      initSocket().then((_) {
        _addMessageListenerInternal(onMessageReceived);
      });
      return;
    }

    _addMessageListenerInternal(onMessageReceived);
  }

  void _addMessageListenerInternal(
    Function(Map<String, dynamic>) onMessageReceived,
  ) {
    // Remove any existing listeners first to prevent duplicates
    _socket?.off('receive_message');
    _socket?.on('receive_message', (data) {
      print('📨 ========= SOCKET MESSAGE RECEIVED =========');
      print('📥 Raw socket data: $data');
      print('🎯 Event received at: ${DateTime.now().toString()}');
      try {
        if (data != null && data is Map<String, dynamic>) {
          onMessageReceived(data);
          print('✅ Message processed successfully');
        } else {
          print('❌ Invalid message data format: $data');
        }
      } catch (e) {
        print('❌ Error processing message: $e');
        print('❌ Stack trace: ${e.toString()}');
      }
    });
  }

  void addTypingListener(Function(String) onUserTyping) {
    print('🔗 Adding typing listener');

    // Ensure socket is connected before adding listener
    if (!isConnected) {
      print('⚠️ Socket not connected, initializing first...');
      initSocket().then((_) {
        _addTypingListenerInternal(onUserTyping);
      });
      return;
    }

    _addTypingListenerInternal(onUserTyping);
  }

  void _addTypingListenerInternal(Function(String) onUserTyping) {
    // Remove any existing listeners first to prevent duplicates
    _socket?.off('user_typing');
    _socket?.on('user_typing', (data) {
      print('⌨️ Raw typing data received: $data');
      try {
        if (data != null &&
            data is Map<String, dynamic> &&
            data.containsKey('userId')) {
          final userId = data['userId'] as String;
          onUserTyping(userId);
        } else {
          print('❌ Invalid typing data format: $data');
        }
      } catch (e) {
        print('❌ Error processing typing event: $e');
      }
    });
  }

  void sendMessage(String receiverId, String content) {
    if (!isConnected) {
      print('❌ Socket not connected. Cannot send message.');
      return;
    }

    final messageData = {'receiverId': receiverId, 'content': content};

    print('📤 Sending message via socket: $messageData');
    _socket?.emit('send_message', messageData);
  }

  void sendTypingNotification(String receiverId) {
    if (!isConnected) {
      print('❌ Socket not connected. Cannot send typing notification.');
      return;
    }

    print('⌨️ Sending typing notification to: $receiverId');
    _socket?.emit('typing', {'receiverId': receiverId});
  }

  // Join a chat room for better message routing
  void joinChatRoom(String chatRoomId) {
    if (!isConnected) {
      print(
        '⏳ Socket not connected yet. Storing room ID for later: $chatRoomId',
      );
      _pendingRoomId = chatRoomId;
      return;
    }

    print('🏠 Joining chat room: $chatRoomId');
    _socket?.emit('join_room', {'roomId': chatRoomId});
  }

  // Leave a chat room
  void leaveChatRoom(String chatRoomId) {
    if (!isConnected) {
      print('❌ Socket not connected. Cannot leave room.');
      return;
    }

    print('🚪 Leaving chat room: $chatRoomId');
    _socket?.emit('leave_room', {'roomId': chatRoomId});
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
    _pendingRoomId = null;
  }

  bool get isConnected => _socket?.connected ?? false;

  // Get detailed connection status
  String getConnectionStatus() {
    if (_socket == null) return 'Not initialized';
    if (_socket!.connected) return 'Connected';
    return 'Disconnected';
  }

  // Remove specific listeners
  void removeMessageListener() {
    print('🔗 Removing message listener');
    _socket?.off('receive_message');
  }

  void removeTypingListener() {
    print('🔗 Removing typing listener');
    _socket?.off('user_typing');
  }

  // Remove all listeners
  void removeAllListeners() {
    print('🔗 Removing all listeners');
    _socket?.off('receive_message');
    _socket?.off('user_typing');
  }

  // Force reconnect method for debugging
  Future<void> forceReconnect() async {
    print('🔄 Force reconnecting socket...');
    _socket?.disconnect();
    _socket = null;
    await initSocket();
  }
}
