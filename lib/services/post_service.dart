import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class PostService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Upload post image
  static Future<String> uploadPostImage(XFile imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get file extension
      String fileName = imageFile.name;
      String extension = fileName.split('.').last.toLowerCase();

      // Map extension to MIME type
      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      // Read bytes for web compatibility
      final bytes = await imageFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data']?['image'] != null) {
          return responseJson['data']['image'];
        }
      }
      throw Exception('Failed to upload image');
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // Create a post
  static Future<Post> createPost({
    required String content,
    XFile? imageFile,
    List<XFile>? imageFiles,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

      // Add multiple images if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          String fileName = imageFile.name;
          String extension = fileName.split('.').last.toLowerCase();

          String mimeType = 'image/jpeg';
          if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'gif') {
            mimeType = 'image/gif';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          }

          final bytes = await imageFile.readAsBytes();

          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }
      // Fallback to single image for backward compatibility
      else if (imageFile != null) {
        String fileName = imageFile.name;
        String extension = fileName.split('.').last.toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }

        final bytes = await imageFile.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

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

  // Report a post
  static Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/reports/post/$postId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'reason': reason}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return true;
        }
      }
      throw Exception('Failed to report post');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('You have already reported this post');
      }
      throw Exception('Failed to report post: $e');
    }
  }

  // Add a comment to a post
  static Future<Comment> addComment({
    required String postId,
    required String content,
    XFile? imageFile,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/comments/post/$postId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        String fileName = imageFile.name;
        String extension = fileName.split('.').last.toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }

        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 10),
      );
      final response = await http.Response.fromStream(streamedResponse);

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

  // ==================== Comment Replies API ====================

  // Add a reply to a comment
  static Future<CommentReply> addReply({
    required String commentId,
    required String content,
    XFile? imageFile,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/comments/$commentId/replies'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        String fileName = imageFile.name;
        String extension = fileName.split('.').last.toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }

        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 10),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return CommentReply.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to add reply: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  // Get replies for a comment
  static Future<CommentRepliesResponse> getReplies({
    required String commentId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/comments/$commentId/replies?page=$page&limit=$limit',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return CommentRepliesResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load replies: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to load replies: $e');
    }
  }

  // Update a reply
  static Future<CommentReply> updateReply({
    required String replyId,
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
          .put(
            Uri.parse('$baseUrl/comments/replies/$replyId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return CommentReply.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update reply: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to update reply: $e');
    }
  }

  // Delete a reply
  static Future<bool> deleteReply(String replyId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/comments/replies/$replyId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
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
          return true;
        }
      } else {
        throw Exception(
          'Failed to delete reply: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
    }
  }

  // ==================== Comment Reactions API ====================

  // Add or update reaction to a comment
  static Future<CommentReaction> addOrUpdateReaction({
    required String commentId,
    required String reactionType,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/comments/$commentId/reactions'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'reactionType': reactionType}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return CommentReaction.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to add reaction: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Remove reaction from a comment
  static Future<bool> removeReaction(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/comments/$commentId/reactions'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          final responseJson = json.decode(response.body);
          if (responseJson['status'] == 'success') {
            return true;
          } else {
            throw Exception(
              'Remove failed: ${responseJson['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          return true;
        }
      } else {
        throw Exception(
          'Failed to remove reaction: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Get all reactions for a comment
  static Future<CommentReactionsResponse> getReactions({
    required String commentId,
    String? reactionType,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      String url = '$baseUrl/comments/$commentId/reactions';
      if (reactionType != null && reactionType.isNotEmpty) {
        url += '?reactionType=$reactionType';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return CommentReactionsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load reactions: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to load reactions: $e');
    }
  }

  // Get current user's reaction for a comment
  static Future<CommentReaction?> getUserReaction(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/comments/$commentId/reactions/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          if (responseJson['data'] != null) {
            return CommentReaction.fromJson(responseJson['data']);
          } else {
            return null; // No reaction found
          }
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to get user reaction: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      throw Exception('Failed to get user reaction: $e');
    }
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorEmail;
  final String authorName;
  final String? authorProfileImage;
  final String content;
  final String? image;
  final List<String>? images;
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
    this.authorProfileImage,
    required this.content,
    this.image,
    this.images,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final authorEmail = json['author']?['email'] ?? '';
    final authorName =
        json['author']?['displayName'] ??
        json['author']?['name'] ??
        authorEmail.split('@')[0];

    return Post(
      id: json['_id'] ?? json['id'] ?? '',
      authorId: json['author']?['_id'] ?? '',
      authorEmail: authorEmail,
      authorName: authorName,
      authorProfileImage: json['author']?['profileImage'],
      content: json['content'] ?? '',
      image: json['image'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
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
  final String? userProfileImage;
  final String content;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int replyCount;
  final int reactionCount;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImage,
    required this.content,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.replyCount = 0,
    this.reactionCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userEmail = json['author']?['email'] ?? json['user']?['email'] ?? '';
    final userName =
        json['author']?['displayName'] ??
        json['author']?['name'] ??
        json['user']?['displayName'] ??
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
      userProfileImage:
          json['author']?['profileImage'] ?? json['user']?['profileImage'],
      content: json['content'] ?? json['text'] ?? '',
      image: json['image'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      replyCount: json['replyCount'] ?? 0,
      reactionCount: json['reactionCount'] ?? 0,
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

// Comment Reply Model
class CommentReply {
  final String id;
  final String commentId;
  final String authorId;
  final String authorName;
  final String? authorProfileImage;
  final String content;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentReply({
    required this.id,
    required this.commentId,
    required this.authorId,
    required this.authorName,
    this.authorProfileImage,
    required this.content,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentReply.fromJson(Map<String, dynamic> json) {
    final authorName =
        json['author']?['displayName'] ??
        json['author']?['name'] ??
        json['author']?['email']?.split('@')[0] ??
        'Unknown';

    return CommentReply(
      id: json['_id'] ?? json['id'] ?? '',
      commentId: json['commentId'] ?? '',
      authorId: json['author']?['_id'] ?? '',
      authorName: authorName,
      authorProfileImage: json['author']?['profileImage'],
      content: json['content'] ?? '',
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

// Comment Reply Response
class CommentRepliesResponse {
  final List<CommentReply> replies;
  final RepliesPagination pagination;
  final String message;

  CommentRepliesResponse({
    required this.replies,
    required this.pagination,
    required this.message,
  });

  factory CommentRepliesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final replies = data.map((reply) => CommentReply.fromJson(reply)).toList();

    return CommentRepliesResponse(
      replies: replies,
      pagination: RepliesPagination.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class RepliesPagination {
  final int currentPage;
  final int totalPages;
  final int totalReplies;
  final bool hasNext;
  final bool hasPrev;

  RepliesPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalReplies,
    required this.hasNext,
    required this.hasPrev,
  });

  factory RepliesPagination.fromJson(Map<String, dynamic> json) {
    return RepliesPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalReplies: json['totalReplies'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

// Comment Reaction Model
class CommentReaction {
  final String id;
  final String commentId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String reactionType;
  final DateTime createdAt;

  CommentReaction({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.reactionType,
    required this.createdAt,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    final userName =
        json['user']?['displayName'] ??
        json['user']?['name'] ??
        json['user']?['email']?.split('@')[0] ??
        'Unknown';

    return CommentReaction(
      id: json['_id'] ?? json['id'] ?? '',
      commentId: json['commentId'] ?? '',
      userId: json['user']?['_id'] ?? '',
      userName: userName,
      userProfileImage: json['user']?['profileImage'],
      reactionType: json['reactionType'] ?? 'like',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// Comment Reactions Response
class CommentReactionsResponse {
  final List<CommentReaction> reactions;
  final Map<String, int> counts;
  final int total;
  final String message;

  CommentReactionsResponse({
    required this.reactions,
    required this.counts,
    required this.total,
    required this.message,
  });

  factory CommentReactionsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> reactionsData = json['data']?['reactions'] ?? [];
    final reactions = reactionsData
        .map((reaction) => CommentReaction.fromJson(reaction))
        .toList();

    // Get counts from backend or calculate from reactions if empty
    Map<String, int> counts = {};
    final Map<String, dynamic> countsData = json['data']?['counts'] ?? {};

    if (countsData.isEmpty && reactions.isNotEmpty) {
      // Backend didn't provide counts, calculate from reactions array
      for (var reaction in reactions) {
        counts[reaction.reactionType] =
            (counts[reaction.reactionType] ?? 0) + 1;
      }
    } else {
      counts = countsData.map((key, value) => MapEntry(key, value as int));
    }

    return CommentReactionsResponse(
      reactions: reactions,
      counts: counts,
      total: json['data']?['total'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
