import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

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
  static const String baseUrl = 'http://localhost:8383';

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
    List<String>? images,
    String status = 'Available',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'contactInfo': {'phone': phone, 'email': email},
        'status': status,
        if (images != null && images.isNotEmpty) 'images': images,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/sell-items'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return SellItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to create sell item');
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
    String itemId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http
          .put(
            Uri.parse('$baseUrl/sell-items/$itemId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(updateData),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return SellItem.fromJson(responseJson['data']);
        }
      }
      throw Exception('Failed to update sell item');
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
