import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/sponsor_ad.dart';

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
}
