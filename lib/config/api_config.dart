import 'package:flutter/foundation.dart';

/// API configuration that manages backend URLs
class ApiConfig {
  // Set this to true when deploying to production
  static const bool useProduction = false;

  /// Base URL for the backend API
  static String get baseUrl {
    if (useProduction) {
      return 'https://auconnectapi-production.up.railway.app';
    }
    // Local development server
    return 'http://localhost:8383';
  }

  /// WebSocket URL for real-time features
  static String get socketUrl {
    if (useProduction) {
      return 'https://auconnectapi-production.up.railway.app';
    }
    return 'http://localhost:8383';
  }

  /// API endpoints
  static const String users = '/users';
  static const String posts = '/posts';
  static const String messages = '/messages';
  static const String comments = '/comments';
  static const String likes = '/likes';
  static const String reports = '/reports';
  static const String friends = '/friends';
  static const String polls = '/polls';
  static const String studySessions = '/study-sessions';
  static const String lostItems = '/lost-items';
  static const String sellItems = '/sell-items';
  static const String notes = '/notes';

  /// Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Log configuration (only in debug mode)
  static void logConfig() {
    if (kDebugMode) {
      print('=== API Configuration ===');
      print('Mode: ${useProduction ? 'Production' : 'Development'}');
      print('Base URL: $baseUrl');
      print('Socket URL: $socketUrl');
      print('========================');
    }
  }
}
