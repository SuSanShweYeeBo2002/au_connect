import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAuthToken = 'auth_token';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyRememberMe = 'remember_me';

  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal();

  // Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get stored user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  // Login user and store credentials
  Future<void> login({
    required String email,
    String? authToken,
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    if (authToken != null) {
      await prefs.setString(_keyAuthToken, authToken);
    }

    // Handle remember me
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_keySavedEmail, email);
    } else {
      await prefs.remove(_keySavedEmail);
    }
  }

  // Logout user and clear stored data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = await isRememberMeEnabled();
    final savedEmail = rememberMe ? await getSavedEmail() : null;

    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthToken);

    // Keep remember me settings if enabled
    if (!rememberMe) {
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedEmail);
    } else {
      await prefs.setString(_keySavedEmail, savedEmail!);
    }
  }

  // Get saved email for remember me
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedEmail);
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Clear all authentication data (for debugging or reset purposes)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
