import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class SellItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> images;
  final Map<String, String> contactInfo;
  final String status;
  final String sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.contactInfo,
    required this.status,
    required this.sellerId,
    this.sellerName,
    this.sellerEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellItem.fromJson(Map<String, dynamic> json) {
    return SellItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      contactInfo: {
        'phone': json['contactInfo']?['phone'] ?? '',
        'email': json['contactInfo']?['email'] ?? '',
      },
      status: json['status'] ?? 'Available',
      sellerId: json['seller'] is String
          ? json['seller']
          : json['seller']?['_id'] ?? '',
      sellerName: json['seller'] is Map ? json['seller']['name'] : null,
      sellerEmail: json['seller'] is Map ? json['seller']['email'] : null,
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
      'price': price,
      'category': category,
      'condition': condition,
      'images': images,
      'contactInfo': contactInfo,
      'status': status,
    };
  }
}

class SellItemService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getToken() async {
    return await AuthService.instance.getAuthToken();
  }

  // Create sell item
  static Future<SellItem> createSellItem({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String phone,
    required String email,
    List<XFile>? imageFiles,
    String status = 'Available',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sell-items'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['condition'] = condition;
      request.fields['contactInfo[phone]'] = phone;
      request.fields['contactInfo[email]'] = email;
      request.fields['status'] = status;

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
          return SellItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to create sell item: ${response.body}');
    } catch (e) {
      throw Exception('Error creating sell item: $e');
    }
  }

  // Get all sell items with filters
  static Future<Map<String, dynamic>> getAllSellItems({
    int page = 1,
    int limit = 10,
    String? category,
    String? status,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        if (condition != null) 'condition': condition,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/sell-items',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          final items = (responseJson['data'] as List)
              .map((item) => SellItem.fromJson(item))
              .toList();
          return {'items': items, 'pagination': responseJson['pagination']};
        }
      }
      throw Exception('Failed to fetch sell items');
    } catch (e) {
      throw Exception('Error fetching sell items: $e');
    }
  }

  // Get sell item by ID
  static Future<SellItem> getSellItemById(String itemId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .get(
            Uri.parse('$baseUrl/sell-items/$itemId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return SellItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to fetch sell item');
    } catch (e) {
      throw Exception('Error fetching sell item: $e');
    }
  }

  // Update sell item
  static Future<SellItem> updateSellItem(
    String itemId, {
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
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
        Uri.parse('$baseUrl/sell-items/$itemId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields only if provided
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (price != null) request.fields['price'] = price.toString();
      if (category != null) request.fields['category'] = category;
      if (condition != null) request.fields['condition'] = condition;
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
          return SellItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to update sell item: ${response.body}');
    } catch (e) {
      throw Exception('Error updating sell item: $e');
    }
  }

  // Delete sell item
  static Future<void> deleteSellItem(String itemId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/sell-items/$itemId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete sell item');
      }
    } catch (e) {
      throw Exception('Error deleting sell item: $e');
    }
  }

  // Get items by seller
  static Future<Map<String, dynamic>> getItemsBySeller(
    String sellerId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/sell-items/seller/$sellerId',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          final items = (responseJson['data'] as List)
              .map((item) => SellItem.fromJson(item))
              .toList();
          return {'items': items, 'pagination': responseJson['pagination']};
        }
      }
      throw Exception('Failed to fetch seller items');
    } catch (e) {
      throw Exception('Error fetching seller items: $e');
    }
  }
}
