import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class UserService {

  static const String baseUrl = 'http://127.0.0.1:8383';

  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  static Future<UserProfile> getUserProfile(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data['data'] ?? data);
      }else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }

    }catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }
  static Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );
      return response.statusCode == 200;
    }catch (e) {
      return false;
    }
  }

}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? avatar;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['email']?.split('@')[0] ?? 'User',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatar: json['avatar'],
    );
  }
}