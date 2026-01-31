import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart';

// Note model
class Note {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? json['id'] ?? '',
      authorId: json['author']?['_id'] ?? json['author'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Notes response with pagination
class NotesResponse {
  final List<Note> notes;
  final NotesPagination pagination;
  final String message;

  NotesResponse({
    required this.notes,
    required this.pagination,
    required this.message,
  });

  factory NotesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final notes = data.map((note) => Note.fromJson(note)).toList();

    return NotesResponse(
      notes: notes,
      pagination: NotesPagination.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

// Pagination model for notes
class NotesPagination {
  final int currentPage;
  final int totalPages;
  final int totalNotes;
  final bool hasNext;
  final bool hasPrev;

  NotesPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalNotes,
    required this.hasNext,
    required this.hasPrev,
  });

  factory NotesPagination.fromJson(Map<String, dynamic> json) {
    return NotesPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalNotes: json['totalNotes'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class NoteService {
  static const String baseUrl = 'http://localhost:8383';

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Create a new note
  static Future<Note> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = {'title': title, 'content': content};

      final response = await http
          .post(
            Uri.parse('$baseUrl/notes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('Create note response status: ${response.statusCode}');
      print('Create note response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Note.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to create note: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error creating note: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error creating note: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error creating note: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to create note: $e');
    }
  }

  // Get all notes for the authenticated user
  static Future<NotesResponse> getNotes({int page = 1}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/notes?page=$page'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get notes response status: ${response.statusCode}');
      print('Get notes response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return NotesResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading notes: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading notes: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading notes: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load notes: $e');
    }
  }

  // Get a specific note by ID
  static Future<Note> getNoteById(String noteId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/notes/$noteId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get note response status: ${response.statusCode}');
      print('Get note response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Note.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load note: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading note: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading note: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading note: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load note: $e');
    }
  }

  // Update a note
  static Future<Note> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = {'title': title, 'content': content};

      final response = await http
          .put(
            Uri.parse('$baseUrl/notes/$noteId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('Update note response status: ${response.statusCode}');
      print('Update note response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Note.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update note: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error updating note: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error updating note: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error updating note: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete a note
  static Future<bool> deleteNote(String noteId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/notes/$noteId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Delete note response status: ${response.statusCode}');
      print('Delete note response body: ${response.body}');

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
          // 204 No Content - deletion successful
          return true;
        }
      } else {
        throw Exception(
          'Failed to delete note: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error deleting note: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error deleting note: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error deleting note: $e');
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to delete note: $e');
    }
  }
}
