import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/auth/login.dart';
import 'package:aina_flutter/core/services/storage_service.dart';

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
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    final token = await StorageService.getToken();
    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
      );
      await fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final requestService = ref.read(requestCodeProvider);
      final response = await requestService.userProfile();

      if (response?.statusCode == 200 && response?.data != null) {
        state = state.copyWith(userData: response?.data);
      } else {
        // If response is not successful, logout the user
        await logout();
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // On any error, logout the user
      await logout();
    }
  }

  Future<void> login(String token) async {
    await StorageService.saveToken(token);
    state = state.copyWith(
      isAuthenticated: true,
      token: token,
    );
    await fetchUserProfile();
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
