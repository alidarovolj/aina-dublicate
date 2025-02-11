import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/core/api/api_client.dart';

const String _tokenKey = 'auth_token';

class AuthState {
  final bool isAuthenticated;
  final bool hasCompletedProfile;
  final String? token;
  final String? refreshToken;
  final String? phoneNumber;
  final Map<String, dynamic>? userData;

  AuthState({
    this.isAuthenticated = false,
    this.hasCompletedProfile = false,
    this.token,
    this.refreshToken,
    this.phoneNumber,
    this.userData,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? hasCompletedProfile,
    String? token,
    String? refreshToken,
    String? phoneNumber,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userData: userData ?? this.userData,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isAuthenticated: false)) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      ApiClient().token = token;
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
      );

      // Fetch user profile
      final requestService = ref.read(requestCodeProvider);
      final response = await requestService.userProfile();

      if (response?.statusCode == 200 && response?.data != null) {
        state = state.copyWith(userData: response?.data);
      } else {
        // If profile fetch fails, log out
        await logout();
      }
    }
  }

  bool get canAccessProfile {
    return state.isAuthenticated && state.userData != null;
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear cache before setting new token
    ApiClient().clearCache();
    await prefs.setString(_tokenKey, token);
    ApiClient().token = token;
    state = state.copyWith(
      isAuthenticated: true,
      token: token,
    );

    // Fetch user profile after setting token
    final requestService = ref.read(requestCodeProvider);
    final response = await requestService.userProfile();

    if (response?.statusCode == 200 && response?.data != null) {
      state = state.copyWith(userData: response?.data);
    } else {
      // If profile fetch fails, log out
      await logout();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiClient().token = null;
    // Clear API client's cache
    ApiClient().clearCache();
    state = AuthState(isAuthenticated: false);
  }

  void updateUserData(Map<String, dynamic> userData) {
    state = state.copyWith(userData: userData);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
