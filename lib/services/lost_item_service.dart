import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class LostItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // Lost or Found
  final String location;
  final DateTime dateReported;
  final List<String> images;
  final Map<String, String> contactInfo;
  final String status;
  final String reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  LostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.location,
    required this.dateReported,
    required this.images,
    required this.contactInfo,
    required this.status,
    required this.reporterId,
    this.reporterName,
    this.reporterEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostItem.fromJson(Map<String, dynamic> json) {
    return LostItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      dateReported: DateTime.parse(
        json['dateReported'] ?? DateTime.now().toIso8601String(),
      ),
      images: List<String>.from(json['images'] ?? []),
      contactInfo: {
        'phone': json['contactInfo']?['phone'] ?? '',
        'email': json['contactInfo']?['email'] ?? '',
      },
      status: json['status'] ?? 'Active',
      reporterId: json['reporter'] is String
          ? json['reporter']
          : json['reporter']?['_id'] ?? '',
      reporterName: json['reporter'] is Map ? json['reporter']['name'] : null,
      reporterEmail: json['reporter'] is Map ? json['reporter']['email'] : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'location': location,
      'dateReported': dateReported.toIso8601String(),
      'images': images,
      'contactInfo': contactInfo,
      'status': status,
    };
  }
}

class LostItemService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Create lost item
  static Future<LostItem> createLostItem({
    required String title,
    required String description,
    required String category,
    required String type,
    required String location,
    required String phone,
    required String email,
    DateTime? dateReported,
    List<XFile>? imageFiles,
    String status = 'Active',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/lost-items'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['type'] = type;
      request.fields['location'] = location;
      request.fields['contactInfo[phone]'] = phone;
      request.fields['contactInfo[email]'] = email;
      request.fields['status'] = status;
      if (dateReported != null) {
        request.fields['dateReported'] = dateReported.toIso8601String();
      }

      // Add multiple images if provided (max 5)
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles.take(5)) {
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

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return LostItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to create lost item: ${response.body}');
    } catch (e) {
      throw Exception('Error creating lost item: $e');
    }
  }

  // Get all lost items with filters
  static Future<Map<String, dynamic>> getAllLostItems({
    int page = 1,
    int limit = 10,
    String? category,
    String? type,
    String? status,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/lost-items',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          final items = (responseJson['data'] as List)
              .map((item) => LostItem.fromJson(item))
              .toList();
          return {'items': items, 'pagination': responseJson['pagination']};
        }
      }
      throw Exception('Failed to fetch lost items');
    } catch (e) {
      throw Exception('Error fetching lost items: $e');
    }
  }

  // Get lost item by ID
  static Future<LostItem> getLostItemById(String itemId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/lost-items/$itemId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return LostItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to fetch lost item');
    } catch (e) {
      throw Exception('Error fetching lost item: $e');
    }
  }

  // Update lost item
  static Future<LostItem> updateLostItem(
    String itemId, {
    String? title,
    String? description,
    String? category,
    String? type,
    String? location,
    String? phone,
    String? email,
    String? status,
    List<String>? keptImageUrls,
    List<XFile>? imageFiles,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/lost-items/$itemId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields only if provided
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (category != null) request.fields['category'] = category;
      if (type != null) request.fields['type'] = type;
      if (location != null) request.fields['location'] = location;
      if (status != null) request.fields['status'] = status;
      if (phone != null) request.fields['contactInfo[phone]'] = phone;
      if (email != null) request.fields['contactInfo[email]'] = email;

      // Add kept image URLs
      if (keptImageUrls != null) {
        for (var i = 0; i < keptImageUrls.length; i++) {
          request.fields['images[$i]'] = keptImageUrls[i];
        }
      }

      // Add multiple images if provided (max 5)
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles.take(5)) {
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

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return LostItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to update lost item: ${response.body}');
    } catch (e) {
      throw Exception('Error updating lost item: $e');
    }
  }

  // Delete lost item
  static Future<void> deleteLostItem(String itemId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/lost-items/$itemId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete lost item');
      }
    } catch (e) {
      throw Exception('Error deleting lost item: $e');
    }
  }

  // Get items by reporter
  static Future<Map<String, dynamic>> getItemsByReporter(
    String reporterId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/lost-items/reporter/$reporterId',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          final items = (responseJson['data'] as List)
              .map((item) => LostItem.fromJson(item))
              .toList();
          return {'items': items, 'pagination': responseJson['pagination']};
        }
      }
      throw Exception('Failed to fetch reporter items');
    } catch (e) {
      throw Exception('Error fetching reporter items: $e');
    }
  }
}
