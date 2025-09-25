import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:8383';

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Get list of users
  static Future<List<User>> getUsers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/users/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          final List<dynamic> data = responseJson['data'];
          return data.map((user) => User.fromJson(user)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'receiverId': receiverId, 'content': content}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get conversations list
  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          final List<dynamic> data = responseJson['data'];
          return data
              .map((conversation) => Conversation.fromJson(conversation))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  // Get conversation messages
  static Future<List<Message>> getConversation(String receiverId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversation/$receiverId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          final List<dynamic> data = responseJson['data'];
          return data.map((message) => Message.fromJson(message)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final bool isOnline;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    // Generate a display name from email if name is not provided
    final name = json['name'] ?? email.split('@')[0];

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: email,
      name: name,
      isOnline: json['isOnline'] ?? false,
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['sender'] != null
          ? json['sender']['_id'] ?? ''
          : json['senderId'] ?? '',
      receiverId: json['receiver'] != null
          ? json['receiver']['_id'] ?? ''
          : json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class Conversation {
  final User user;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      user: User.fromJson(json['user']),
      lastMessage: Message.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
