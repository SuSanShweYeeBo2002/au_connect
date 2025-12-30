import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart';

class FriendService {
  static const String baseUrl = 'http://127.0.0.1:8383';

  // Get the token from AuthService
  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Send a friend request
  static Future<Friend> sendFriendRequest({required String recipientId}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/friends/request'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'recipientId': recipientId}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Friend.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to send friend request',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      rethrow;
    }
  }

  // Get received pending friend requests
  static Future<FriendRequestsResponse> getPendingRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/friends/requests/pending'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return FriendRequestsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load pending requests: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load pending requests: $e');
    }
  }

  // Get sent friend requests
  static Future<FriendRequestsResponse> getSentRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/friends/requests/sent'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return FriendRequestsResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load sent requests: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load sent requests: $e');
    }
  }

  // Accept or reject a friend request
  static Future<Friend> updateFriendRequest({
    required String requestId,
    required FriendStatus status,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .put(
            Uri.parse('$baseUrl/friends/request/$requestId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': status.name}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return Friend.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to update friend request',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      rethrow;
    }
  }

  // Cancel a sent friend request
  static Future<bool> cancelFriendRequest(String requestId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/friends/request/$requestId'),
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
              'Cancel failed: ${responseJson['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          return true;
        }
      } else {
        throw Exception(
          'Failed to cancel friend request: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to cancel friend request: $e');
    }
  }

  // Get friends list
  static Future<FriendsListResponse> getFriendsList() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/friends/list'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return FriendsListResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load friends list: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load friends list: $e');
    }
  }

  // Unfriend a user
  static Future<bool> unfriend(String friendId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/friends/$friendId'),
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
              'Unfriend failed: ${responseJson['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          return true;
        }
      } else {
        throw Exception('Failed to unfriend: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to unfriend: $e');
    }
  }

  // Block a user
  static Future<BlockUser> blockUser(String blockedId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .post(
            Uri.parse('$baseUrl/blocks'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'blockedId': blockedId}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          return BlockUser.fromJson(responseJson['data']);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to block user');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      rethrow;
    }
  }

  // Unblock a user
  static Future<bool> unblockUser(String blockedId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/blocks/$blockedId'),
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
              'Unblock failed: ${responseJson['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          return true;
        }
      } else {
        throw Exception('Failed to unblock user: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to unblock user: $e');
    }
  }

  // Get blocked users list
  static Future<BlockedUsersResponse> getBlockedUsers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/blocks/list'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return BlockedUsersResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load blocked users: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load blocked users: $e');
    }
  }

  // Get users who blocked me
  static Future<BlockedUsersResponse> getUsersWhoBlockedMe() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/blocks/who-blocked-me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return BlockedUsersResponse.fromJson(responseJson);
        } else {
          throw Exception(
            'Server error: ${responseJson['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load users who blocked me: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection and try again',
      );
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      throw Exception('Failed to load users who blocked me: $e');
    }
  }

  // Check if blocked by a specific user (bidirectional check)
  // Returns true if either you blocked them OR they blocked you
  static Future<bool> checkIfBlockedByUser(String userId) async {
    try {
      // Check both directions in parallel for better performance
      final results = await Future.wait([
        getBlockedUsers(),
        getUsersWhoBlockedMe(),
      ]);

      final blockedByYou = results[0];
      final blockedYou = results[1];

      // Check if you blocked them
      final youBlockedThem = blockedByYou.blockedUsers.any(
        (block) => block.blockedId == userId,
      );

      if (youBlockedThem) {
        return true;
      }

      // Check if they blocked you
      final theyBlockedYou = blockedYou.blockedUsers.any(
        (block) => block.blockedId == userId,
      );

      if (theyBlockedYou) {
        return true;
      }

      return false;
    } catch (e) {
      return false; // Assume not blocked on error
    }
  }
}

class Friend {
  final String id;
  final String requesterId;
  final String recipientId;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FriendUser? requester;
  final FriendUser? recipient;

  Friend({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.requester,
    this.recipient,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    // Handle requesterId - can be string or object
    String requesterId = '';
    FriendUser? requester;
    if (json['requesterId'] != null) {
      if (json['requesterId'] is String) {
        requesterId = json['requesterId'];
      } else if (json['requesterId'] is Map) {
        requester = FriendUser.fromJson(json['requesterId']);
        requesterId = requester.id;
      }
    }

    // Handle recipientId - can be string or object
    String recipientId = '';
    FriendUser? recipient;
    if (json['recipientId'] != null) {
      if (json['recipientId'] is String) {
        recipientId = json['recipientId'];
      } else if (json['recipientId'] is Map) {
        recipient = FriendUser.fromJson(json['recipientId']);
        recipientId = recipient.id;
      }
    }

    // Handle 'friend' field from friends list API
    if (json['friend'] != null) {
      recipient = FriendUser.fromJson(json['friend']);
      recipientId = recipient.id;
    }

    // Also check for 'requester' and 'recipient' fields if not already populated
    if (json['requester'] != null && requester == null) {
      requester = FriendUser.fromJson(json['requester']);
    }
    if (json['recipient'] != null && recipient == null) {
      recipient = FriendUser.fromJson(json['recipient']);
    }

    return Friend(
      id: json['_id'] ?? json['id'] ?? '',
      requesterId: requesterId,
      recipientId: recipientId,
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['friendsSince'] != null
          ? DateTime.parse(json['friendsSince'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : json['friendsSince'] != null
          ? DateTime.parse(json['friendsSince'])
          : DateTime.now(),
      requester: requester,
      recipient: recipient,
    );
  }

  static FriendStatus _parseStatus(dynamic status) {
    if (status == null) return FriendStatus.pending;
    switch (status.toString().toLowerCase()) {
      case 'accepted':
        return FriendStatus.accepted;
      case 'rejected':
        return FriendStatus.rejected;
      case 'pending':
      default:
        return FriendStatus.pending;
    }
  }
}

enum FriendStatus { pending, accepted, rejected }

class FriendUser {
  final String id;
  final String email;
  final String name;
  final String? avatar;

  FriendUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    return FriendUser(
      id: json['_id'] ?? json['id'] ?? '',
      email: email,
      name: json['name'] ?? email.split('@')[0],
      avatar: json['avatar'],
    );
  }
}

class FriendsListResponse {
  final List<Friend> friends;
  final String message;

  FriendsListResponse({required this.friends, required this.message});

  factory FriendsListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final friends = data.map((friend) => Friend.fromJson(friend)).toList();

    return FriendsListResponse(
      friends: friends,
      message: json['message'] ?? '',
    );
  }
}

class FriendRequestsResponse {
  final List<Friend> requests;
  final String message;

  FriendRequestsResponse({required this.requests, required this.message});

  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final requests = data.map((request) => Friend.fromJson(request)).toList();

    return FriendRequestsResponse(
      requests: requests,
      message: json['message'] ?? '',
    );
  }
}

class BlockUser {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
  final BlockedUserInfo? blockedUser;

  BlockUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
    this.blockedUser,
  });

  factory BlockUser.fromJson(Map<String, dynamic> json) {
    // Backend returns: { _id, user: { _id, email, name }, blockedAt }
    final userId = json['user'] != null
        ? (json['user']['_id'] ?? json['user']['id'] ?? '')
        : json['blockedId'] ?? '';

    return BlockUser(
      id: json['_id'] ?? json['id'] ?? '',
      blockerId: json['blockerId'] ?? '',
      blockedId: userId,
      createdAt: json['blockedAt'] != null
          ? DateTime.parse(json['blockedAt'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
      blockedUser: json['user'] != null
          ? BlockedUserInfo.fromJson(json['user'])
          : (json['blockedUser'] != null
                ? BlockedUserInfo.fromJson(json['blockedUser'])
                : null),
    );
  }
}

class BlockedUserInfo {
  final String id;
  final String email;
  final String name;

  BlockedUserInfo({required this.id, required this.email, required this.name});

  factory BlockedUserInfo.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    return BlockedUserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      email: email,
      name: json['name'] ?? email.split('@')[0],
    );
  }
}

class BlockedUsersResponse {
  final List<BlockUser> blockedUsers;
  final String message;

  BlockedUsersResponse({required this.blockedUsers, required this.message});

  factory BlockedUsersResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final blockedUsers = data
        .map((block) => BlockUser.fromJson(block))
        .toList();

    return BlockedUsersResponse(
      blockedUsers: blockedUsers,
      message: json['message'] ?? '',
    );
  }
}
