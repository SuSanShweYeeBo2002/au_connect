import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class PostService {
  static const String baseUrl = 'http://localhost:8383';

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Create a post
  static Future<Post> createPost({
    required String content,
    String? image,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = <String, dynamic>{'content': content};
      if (image != null && image.isNotEmpty) {
        requestBody['image'] = image;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Create post response status: ${response.statusCode}');
      print('Create post response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Post.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Invalid response format: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to create post: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts list
  static Future<List<Post>> getPosts() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
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
          return data.map((post) => Post.fromJson(post)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final String? image;
  final int likes;
  final List<Comment> comments;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.image,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? json['id'] ?? '',
      authorId: json['author']?['_id'] ?? json['authorId'] ?? '',
      authorName:
          json['author']?['name'] ??
          json['author']?['email']?.split('@')[0] ??
          'Unknown',
      content: json['content'] ?? '',
      image: json['image'],
      likes: json['likes'] ?? 0,
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((comment) => Comment.fromJson(comment))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user']?['_id'] ?? json['userId'] ?? '',
      userName:
          json['user']?['name'] ??
          json['user']?['email']?.split('@')[0] ??
          'Unknown',
      text: json['text'] ?? json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
