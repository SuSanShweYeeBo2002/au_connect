import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart';

class PollService {
  static const String baseUrl = 'http://localhost:8383';

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Create a poll
  static Future<Poll> createPoll({
    required String question,
    required List<String> options,
    DateTime? expiresAt,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = <String, dynamic>{
        'question': question,
        'options': options,
      };

      if (expiresAt != null) {
        requestBody['expiresAt'] = expiresAt.toIso8601String();
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/polls'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('Create poll response status: ${response.statusCode}');
      print('Create poll response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Poll.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to create poll: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error creating poll: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error creating poll: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error creating poll: $e');
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get polls list
  static Future<PollsResponse> getPolls({int page = 1}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/polls?page=$page'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Get polls response status: ${response.statusCode}');
      print('Get polls response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return PollsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load polls: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Timeout error loading polls: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error loading polls: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error loading polls: $e');
      throw Exception('Failed to load polls: $e');
    }
  }

  // Vote on a poll
  static Future<Poll> votePoll({
    required String pollId,
    required int optionIndex,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/polls/$pollId/vote'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'optionIndex': optionIndex}),
          )
          .timeout(Duration(seconds: 10));

      print('Vote poll response status: ${response.statusCode}');
      print('Vote poll response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Poll.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to vote: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error voting: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error voting: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error voting: $e');
      throw Exception('Failed to vote: $e');
    }
  }

  // Delete a poll
  static Future<bool> deletePoll(String pollId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/polls/$pollId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Delete poll response status: ${response.statusCode}');
      print('Delete poll response body: ${response.body}');

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
          'Failed to delete poll: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error deleting poll: $e');
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      print('Network error deleting poll: $e');
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      print('Error deleting poll: $e');
      throw Exception('Failed to delete poll: $e');
    }
  }
}

class Voter {
  final String id;
  final String email;
  final String name;

  Voter({required this.id, required this.email, required this.name});

  factory Voter.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    final name = json['name'] ?? email.split('@')[0];
    return Voter(id: json['_id'] ?? json['id'] ?? '', email: email, name: name);
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'email': email, 'name': name};
  }

  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@')[0];
    return 'User';
  }

  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }
}

class PollOption {
  final String text;
  final int votes;
  final List<Voter> voters;

  PollOption({required this.text, required this.votes, required this.voters});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    final List<dynamic> votersData = json['voters'] ?? [];
    final voters = votersData.map((voter) {
      // Handle both string IDs and user objects
      if (voter is String) {
        return Voter(id: voter, email: '', name: '');
      } else if (voter is Map<String, dynamic>) {
        return Voter.fromJson(voter);
      }
      return Voter(id: '', email: '', name: '');
    }).toList();

    return PollOption(
      text: json['text'] ?? '',
      votes: json['votes'] ?? 0,
      voters: voters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'votes': votes,
      'voters': voters.map((v) => v.toJson()).toList(),
    };
  }
}

class Poll {
  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isExpired;
  final int? userVotedIndex;

  Poll({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.question,
    required this.options,
    required this.totalVotes,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    required this.isExpired,
    this.userVotedIndex,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    final authorEmail = json['author']?['email'] ?? '';
    final authorName = json['author']?['name'] ?? authorEmail.split('@')[0];

    final List<dynamic> optionsData = json['options'] ?? [];
    final options = optionsData.map((opt) => PollOption.fromJson(opt)).toList();

    return Poll(
      id: json['_id'] ?? json['id'] ?? '',
      authorId: json['author']?['_id'] ?? '',
      authorName: authorName,
      authorEmail: authorEmail,
      question: json['question'] ?? '',
      options: options,
      totalVotes: json['totalVotes'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      isExpired: json['isExpired'] ?? json['expired'] ?? false,
      userVotedIndex: json['votedOptionIndex'] ?? json['userVotedIndex'],
    );
  }

  double getOptionPercentage(int index) {
    if (totalVotes == 0) return 0;
    return (options[index].votes / totalVotes) * 100;
  }

  bool get hasVoted => userVotedIndex != null;
}

class PollsResponse {
  final List<Poll> polls;
  final PollPagination pagination;
  final String message;

  PollsResponse({
    required this.polls,
    required this.pagination,
    required this.message,
  });

  factory PollsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final polls = data.map((poll) => Poll.fromJson(poll)).toList();

    return PollsResponse(
      polls: polls,
      pagination: PollPagination.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class PollPagination {
  final int currentPage;
  final int totalPages;
  final int totalPolls;
  final bool hasNext;
  final bool hasPrev;

  PollPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalPolls,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PollPagination.fromJson(Map<String, dynamic> json) {
    return PollPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalPolls: json['totalPolls'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}
