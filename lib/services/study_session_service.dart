import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'auth_service.dart';

class StudySessionService {
  static const String baseUrl = 'http://localhost:8383';
  static const String endpoint = '/study-sessions';

  static StudySessionService? _instance;
  static StudySessionService get instance {
    _instance ??= StudySessionService._internal();
    return _instance!;
  }

  StudySessionService._internal();

  // Helper method to get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.instance.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // 1. Create Study Session
  Future<Map<String, dynamic>> createStudySession({
    required String title,
    required String description,
    required String subject,
    required String platform,
    String? platformLink,
    required String studyType,
    String? location,
    int? maxParticipants,
    required DateTime scheduledDate,
    required int duration,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'description': description,
        'subject': subject,
        'platform': platform,
        'platformLink': platformLink,
        'studyType': studyType,
        'location': location,
        'maxParticipants': maxParticipants,
        'scheduledDate': scheduledDate.toIso8601String(),
        'duration': duration,
      });

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'session': StudySession.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 2. Get All Study Sessions
  Future<Map<String, dynamic>> getAllStudySessions({
    int page = 1,
    int limit = 10,
    String? status,
    String? studyType,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (studyType != null) 'studyType': studyType,
      };

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final sessions = (data['data'] as List)
            .map((json) => StudySession.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': data['message'],
          'sessions': sessions,
          'pagination': StudySessionPagination.fromJson(data['pagination']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch study sessions',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 3. Get Study Session by ID
  Future<Map<String, dynamic>> getStudySessionById(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint/$sessionId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'session': StudySession.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 4. Update Study Session
  Future<Map<String, dynamic>> updateStudySession({
    required String sessionId,
    String? title,
    String? description,
    String? subject,
    String? platform,
    String? platformLink,
    String? studyType,
    String? location,
    int? maxParticipants,
    DateTime? scheduledDate,
    int? duration,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> bodyMap = {};

      if (title != null) bodyMap['title'] = title;
      if (description != null) bodyMap['description'] = description;
      if (subject != null) bodyMap['subject'] = subject;
      if (platform != null) bodyMap['platform'] = platform;
      if (platformLink != null) bodyMap['platformLink'] = platformLink;
      if (studyType != null) bodyMap['studyType'] = studyType;
      if (location != null) bodyMap['location'] = location;
      if (maxParticipants != null) bodyMap['maxParticipants'] = maxParticipants;
      if (scheduledDate != null) {
        bodyMap['scheduledDate'] = scheduledDate.toIso8601String();
      }
      if (duration != null) bodyMap['duration'] = duration;
      if (status != null) bodyMap['status'] = status;

      final body = jsonEncode(bodyMap);

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint/$sessionId'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'session': StudySession.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 5. Delete Study Session
  Future<Map<String, dynamic>> deleteStudySession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint/$sessionId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 6. Join Study Session
  Future<Map<String, dynamic>> joinStudySession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint/$sessionId/join'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'session': StudySession.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to join study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 7. Leave Study Session
  Future<Map<String, dynamic>> leaveStudySession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint/$sessionId/leave'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to leave study session',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 8. Get Session Participants
  Future<Map<String, dynamic>> getSessionParticipants({
    required String sessionId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl$endpoint/$sessionId/participants',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final participants = (data['data'] as List)
            .map((json) => Participant.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': data['message'],
          'participants': participants,
          'pagination': ParticipantPagination.fromJson(data['pagination']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch participants',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

// Models
class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'_id': id, 'email': email};
}

class StudySession {
  final String id;
  final User creator;
  final String title;
  final String description;
  final String subject;
  final String platform;
  final String? platformLink;
  final String studyType;
  final String? location;
  final int? maxParticipants;
  final int currentParticipants;
  final DateTime scheduledDate;
  final int duration;
  final String status;
  final bool isActive;
  final bool isFull;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudySession({
    required this.id,
    required this.creator,
    required this.title,
    required this.description,
    required this.subject,
    required this.platform,
    this.platformLink,
    required this.studyType,
    this.location,
    this.maxParticipants,
    required this.currentParticipants,
    required this.scheduledDate,
    required this.duration,
    required this.status,
    required this.isActive,
    required this.isFull,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['_id'] ?? json['id'] ?? '',
      creator: User.fromJson(json['creator'] ?? {}),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      platform: json['platform'] ?? '',
      platformLink: json['platformLink'],
      studyType: json['studyType'] ?? '',
      location: json['location'],
      maxParticipants: json['maxParticipants'],
      currentParticipants: json['currentParticipants'] ?? 0,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      duration: json['duration'] ?? 0,
      status: json['status'] ?? '',
      isActive: json['isActive'] ?? true,
      isFull: json['isFull'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = scheduledDate.difference(now);
    if (diff.inDays == 0) {
      return 'Today ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days';
    }
    return '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
  }
}

class Participant {
  final User user;
  final DateTime joinedAt;

  Participant({required this.user, required this.joinedAt});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      user: User.fromJson(json['user'] ?? {}),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

class StudySessionPagination {
  final int currentPage;
  final int totalPages;
  final int totalSessions;
  final bool hasNext;
  final bool hasPrev;

  StudySessionPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalSessions,
    required this.hasNext,
    required this.hasPrev,
  });

  factory StudySessionPagination.fromJson(Map<String, dynamic> json) {
    return StudySessionPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalSessions: json['totalSessions'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class ParticipantPagination {
  final int currentPage;
  final int totalPages;
  final int totalParticipants;
  final bool hasNext;
  final bool hasPrev;

  ParticipantPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalParticipants,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ParticipantPagination.fromJson(Map<String, dynamic> json) {
    return ParticipantPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalParticipants: json['totalParticipants'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}
