import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage Service
/// Handles local storage for token, user profile, and other cached data

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _profileKey = 'user_profile';
  static const String _isLoggedInKey = 'is_logged_in';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ============ Token Management ============

  /// Save auth token
  Future<bool> saveToken(String token) async {
    return await _prefs!.setString(_tokenKey, token);
  }

  /// Get auth token
  String? getToken() {
    return _prefs!.getString(_tokenKey);
  }

  /// Check if token exists
  bool hasToken() {
    return _prefs!.containsKey(_tokenKey) && 
           _prefs!.getString(_tokenKey)?.isNotEmpty == true;
  }

  /// Remove token (logout)
  Future<bool> removeToken() async {
    return await _prefs!.remove(_tokenKey);
  }

  // ============ Login State ============

  /// Set logged in state
  Future<bool> setLoggedIn(bool value) async {
    return await _prefs!.setBool(_isLoggedInKey, value);
  }

  /// Check if logged in
  bool isLoggedIn() {
    return _prefs!.getBool(_isLoggedInKey) ?? false;
  }

  // ============ Profile Caching ============

  /// Save profile data
  Future<bool> saveProfile(Map<String, dynamic> profile) async {
    final jsonString = jsonEncode(profile);
    return await _prefs!.setString(_profileKey, jsonString);
  }

  /// Get cached profile
  Map<String, dynamic>? getProfile() {
    final jsonString = _prefs!.getString(_profileKey);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if profile is cached
  bool hasProfile() {
    return _prefs!.containsKey(_profileKey);
  }

  /// Clear profile cache
  Future<bool> clearProfile() async {
    return await _prefs!.remove(_profileKey);
  }

  // ============ Clear All Data ============

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_profileKey);
    await _prefs!.setBool(_isLoggedInKey, false);
  }
}
