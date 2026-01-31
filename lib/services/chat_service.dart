import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ChatService {
  static const String baseUrl =
      'https://auconnectapi-production.up.railway.app';

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
  // Helper to format error messages for users
  static String _formatErrorMessage(String errorMessage) {
    // Parse blocked user errors
    if (errorMessage.contains('User is blocked') ||
        errorMessage.contains('has blocked you')) {
      return 'Unable to send message. You cannot message this user due to blocking restrictions.';
    }

    // Parse other common errors
    if (errorMessage.contains('No authentication token')) {
      return 'Please sign in again to send messages.';
    }

    if (errorMessage.contains('Network error') ||
        errorMessage.contains('connection')) {
      return 'Connection error. Please check your internet and try again.';
    }

    // Return original message if no match
    return errorMessage;
  }

  static Future<Message> sendMessage({
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

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Message.fromJson(responseJson['data']);
        } else {
          final errorMsg = responseJson['message'] ?? 'Unknown error';
          throw Exception(_formatErrorMessage(errorMsg));
        }
      } else {
        // Try to parse error message from response body
        try {
          final errorJson = json.decode(response.body);
          final errorMsg = errorJson['message'] ?? 'Failed to send message';
          throw Exception(_formatErrorMessage(errorMsg));
        } catch (_) {
          throw Exception('Failed to send message. Please try again.');
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      // Check if error is already formatted
      if (e is Exception &&
          e.toString().startsWith('Exception: Unable to send message')) {
        rethrow;
      }
      throw Exception(_formatErrorMessage(e.toString()));
    }
  }

  // Delete a message
  static Future<bool> deleteMessage(String messageId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Delete message response status: ${response.statusCode}');
      print('Delete message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Some APIs return 200 with success response, others return 204 (No Content)
        if (response.body.isNotEmpty) {
          final responseJson = json.decode(response.body);
          if (responseJson['status'] == 'success') {
            return true;
          } else {
            throw Exception(
              'Delete failed: ${responseJson['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          // 204 No Content - deletion successful
          return true;
        }
      } else {
        throw Exception(
          'Failed to delete message: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Mark message as read
  static Future<bool> markMessageAsRead(String receiverId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/messages/read/$receiverId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Mark as read response status: ${response.statusCode}');
      print('Mark as read response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return true;
        } else {
          throw Exception(
            'Mark as read failed: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to mark messages as read: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      throw Exception('Failed to mark messages as read: $e');
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
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.isOnline = false,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    // Generate a display name from email if name is not provided
    final name = json['displayName'] ?? json['name'] ?? email.split('@')[0];

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: email,
      name: name,
      isOnline: json['isOnline'] ?? false,
      profileImage: json['profileImage'],
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
          ? _parseUtcTimestamp(json['createdAt'])
          : json['timestamp'] != null
          ? _parseUtcTimestamp(json['timestamp'])
          : DateTime.now(),
    );
  }

  // Helper method to parse UTC timestamp and convert to local time
  static DateTime _parseUtcTimestamp(String timestamp) {
    try {
      // Parse the timestamp (handles both UTC 'Z' format and ISO format)
      final dateTime = DateTime.parse(timestamp);

      // If the timestamp doesn't have timezone info, treat it as UTC
      if (dateTime.timeZoneOffset == Duration.zero &&
          !timestamp.endsWith('Z')) {
        return DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
        ).toLocal();
      }

      // If it's already UTC (with 'Z') or has timezone info, convert to local
      return dateTime.toLocal();
    } catch (e) {
      print('❌ Error parsing timestamp: $timestamp, error: $e');
      return DateTime.now();
    }
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
