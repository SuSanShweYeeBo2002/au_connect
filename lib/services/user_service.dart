import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8383';

  // Get current authenticated user's profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.body}');
    }
  }

  // Update current user's profile
  static Future<Map<String, dynamic>> updateCurrentUser({
    String? email,
    String? password,
  }) async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    if (email == null && password == null) {
      throw Exception('At least one field is required');
    }

    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Get specific user by ID
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }
}
