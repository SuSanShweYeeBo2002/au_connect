import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/sponsor_ad.dart';
import 'auth_service.dart';

class SponsorAdService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get all active sponsor ads
  static Future<List<SponsorAd>> getActiveAds() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sponsor-ads/active'))
          .timeout(Duration(seconds: 10));

      print('Get active sponsor ads status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          final List<dynamic> adsJson = responseJson['data'] ?? [];
          return adsJson.map((json) => SponsorAd.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching active sponsor ads: $e');
      return [];
    }
  }

  /// Track ad impression
  static Future<void> trackImpression(String adId) async {
    try {
      await http
          .post(Uri.parse('$baseUrl/sponsor-ads/$adId/impression'))
          .timeout(Duration(seconds: 5));
    } catch (e) {
      print('Error tracking impression: $e');
    }
  }

  /// Track ad click
  static Future<void> trackClick(String adId) async {
    try {
      await http
          .post(Uri.parse('$baseUrl/sponsor-ads/$adId/click'))
          .timeout(Duration(seconds: 5));
    } catch (e) {
      print('Error tracking click: $e');
    }
  }

  /// Create sponsor ad (Admin only)
  static Future<SponsorAd> createSponsorAd({
    required XFile imageFile,
    required String title,
    required String sponsorName,
    required String link,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String status = 'active',
  }) async {
    try {
      final token = await AuthService.instance.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sponsor-ads'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add image
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
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add fields
      request.fields['title'] = title;
      request.fields['sponsorName'] = sponsorName;
      request.fields['link'] = link;
      if (description != null) {
        request.fields['description'] = description;
      }
      request.fields['startDate'] = startDate.toIso8601String();
      request.fields['endDate'] = endDate.toIso8601String();
      request.fields['status'] = status;

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('Create sponsor ad status: ${response.statusCode}');
      print('Create sponsor ad response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson['status'] == 'success') {
          return SponsorAd.fromJson(responseJson['data']);
        }
      }

      throw Exception('Failed to create sponsor ad: ${response.body}');
    } catch (e) {
      print('Error creating sponsor ad: $e');
      throw Exception('Failed to create sponsor ad: $e');
    }
  }
}
