import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _userDataKey = 'user_data';
  static const String _isAuthenticatedKey = 'is_authenticated';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isAuthenticatedKey, true);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }

  static Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = jsonEncode(userData);
    await prefs.setString(_userDataKey, userDataJson);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(_userDataKey);
    if (userDataJson == null || userDataJson.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Ошибка при декодировании данных пользователя: $e');
      return null;
    }
  }

  static Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isAuth = prefs.getBool(_isAuthenticatedKey) ?? false;

    return token != null && token.isNotEmpty && isAuth;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }
}
