import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';

class AuthState {
  final String? token;

  AuthState({this.token});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await StorageService.getToken();
    state = AuthState(token: token);
  }

  void setToken(String? token) {
    state = AuthState(token: token);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
