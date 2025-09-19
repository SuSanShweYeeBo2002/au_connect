import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  final String _serverUrl =
      'http://localhost:8383'; // Update with your server URL

  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  Future<void> initSocket() async {
    if (_socket?.connected ?? false) return;

    final token = await AuthService.instance.getAuthToken();
    if (token == null) return;

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('Socket connected');
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket?.onError((error) {
      print('Socket error: $error');
    });
  }

  void addMessageListener(Function(Map<String, dynamic>) onMessageReceived) {
    _socket?.on('receive_message', (data) {
      onMessageReceived(data as Map<String, dynamic>);
    });
  }

  void addTypingListener(Function(String) onUserTyping) {
    _socket?.on('user_typing', (data) {
      final userId = data['userId'] as String;
      onUserTyping(userId);
    });
  }

  void sendMessage(String receiverId, String content) {
    _socket?.emit('send_message', {
      'receiverId': receiverId,
      'content': content,
    });
  }

  void sendTypingNotification(String receiverId) {
    _socket?.emit('typing', {'receiverId': receiverId});
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
