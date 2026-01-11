import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'https://au-connect-api.onrender.com';

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
    String? displayName,
  }) async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    if (email == null && password == null && displayName == null) {
      throw Exception('At least one field is required');
    }

    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (displayName != null) body['displayName'] = displayName;

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

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(
    XFile imageFile,
  ) async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/me/profile-image'),
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
        'profileImage',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to upload profile image: ${response.body}');
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage() async {
    final token = await AuthService.instance.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/users/me/profile-image'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete profile image: ${response.body}');
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

  // Resend verification email
  static Future<Map<String, dynamic>> resendVerificationEmail(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to resend verification email',
      );
    }
  }
}
