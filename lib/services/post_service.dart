import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/posts'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('Create post response status: ${response.statusCode}');
      print('Create post response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Post.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to create post: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error creating post: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error creating post: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error creating post: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts list
  static Future<PostsResponse> getPosts({int page = 1}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/posts?page=$page'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get posts response status: ${response.statusCode}');
      print('Get posts response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          // Handle both empty and non-empty data arrays
          return PostsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading posts: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading posts: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading posts: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load posts: $e');
    }
  }

  // Get posts by author ID
  static Future<PostsResponse> getPostsByAuthor({
    required String authorId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/posts/author/$authorId?page=$page&limit=$limit',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get posts by author response status: ${response.statusCode}');
      print('Get posts by author response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return PostsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load posts by author: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading posts by author: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading posts by author: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading posts by author: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load posts by author: $e');
    }
  }

  // Like/Unlike a post
  static Future<LikeResponse> likePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/likes/post/$postId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Like post response status: ${response.statusCode}');
      print('Like post response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return LikeResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to like post: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error liking post: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error liking post: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error liking post: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to like post: $e');
    }
  }

  // Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/posts/$postId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Delete post response status: ${response.statusCode}');
      print('Delete post response body: ${response.body}');

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
          'Failed to delete post: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error deleting post: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error deleting post: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error deleting post: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to delete post: $e');
    }
  }

  // Add a comment to a post
  static Future<Comment> addComment({
    required String postId,
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/comments/post/$postId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('Add comment response status: ${response.statusCode}');
      print('Add comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Comment.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to add comment: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error adding comment: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error adding comment: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error adding comment: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a post
  static Future<CommentsResponse> getComments({
    required String postId,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/comments/post/$postId?page=$page'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get comments response status: ${response.statusCode}');
      print('Get comments response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return CommentsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading comments: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading comments: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading comments: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load comments: $e');
    }
  }

  // Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/comments/$commentId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Delete comment response status: ${response.statusCode}');
      print('Delete comment response body: ${response.body}');

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
          'Failed to delete comment: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error deleting comment: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error deleting comment: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error deleting comment: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to delete comment: $e');
    }
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorEmail;
  final String authorName;
  final String content;
  final String? image;
  final int likeCount;
  final int commentCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorEmail,
    required this.authorName,
    required this.content,
    this.image,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final authorEmail = json['author']?['email'] ?? '';
    final authorName = json['author']?['name'] ?? authorEmail.split('@')[0];

    return Post(
      id: json['_id'] ?? json['id'] ?? '',
      authorId: json['author']?['_id'] ?? '',
      authorEmail: authorEmail,
      authorName: authorName,
      content: json['content'] ?? '',
      image: json['image'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class PostsResponse {
  final List<Post> posts;
  final Pagination pagination;
  final String message;

  PostsResponse({
    required this.posts,
    required this.pagination,
    required this.message,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final posts = data.map((post) => Post.fromJson(post)).toList();

    return PostsResponse(
      posts: posts,
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalPosts;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalPosts,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalPosts: json['totalPosts'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userEmail;
  final String content;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.content,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userEmail = json['author']?['email'] ?? json['user']?['email'] ?? '';
    final userName =
        json['author']?['name'] ??
        json['user']?['name'] ??
        userEmail.split('@')[0];

    return Comment(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId:
          json['author']?['_id'] ??
          json['user']?['_id'] ??
          json['userId'] ??
          '',
      userName: userName,
      userEmail: userEmail,
      content: json['content'] ?? json['text'] ?? '',
      image: json['image'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class LikeResponse {
  final String action;
  final int likeCount;
  final String message;

  LikeResponse({
    required this.action,
    required this.likeCount,
    required this.message,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      action: json['data']?['action'] ?? '',
      likeCount: json['data']?['likeCount'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class CommentsResponse {
  final List<Comment> comments;
  final CommentsPagination pagination;
  final String message;

  CommentsResponse({
    required this.comments,
    required this.pagination,
    required this.message,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final comments = data.map((comment) => Comment.fromJson(comment)).toList();

    return CommentsResponse(
      comments: comments,
      pagination: CommentsPagination.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class CommentsPagination {
  final int currentPage;
  final int totalPages;
  final int totalComments;
  final bool hasNext;
  final bool hasPrev;

  CommentsPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalComments,
    required this.hasNext,
    required this.hasPrev,
  });

  factory CommentsPagination.fromJson(Map<String, dynamic> json) {
    return CommentsPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalComments: json['totalComments'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}
