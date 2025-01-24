import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tokenKey = 'auth_token';

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final Map<String, dynamic>? userData;

  AuthState({
    required this.isAuthenticated,
    this.token,
    this.userData,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
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
    await prefs.setString(_tokenKey, token);
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
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
