import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/auth/login.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

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

  @override
  void dispose() {
    // Clean up any resources here
    debugPrint('🧹 AuthNotifier disposed');
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      // Проверяем авторизацию через StorageService
      final isAuthenticated = await StorageService.isAuthenticated();
      if (!isAuthenticated) {
        return;
      }

      // Получаем токен
      final token = await StorageService.getToken();
      if (token == null) {
        return;
      }

      // Устанавливаем токен в ApiClient
      ApiClient().token = token;

      // Получаем данные пользователя из локального хранилища
      final userData = await StorageService.getUserData();

      // Проверяем, что нотифаер все еще активен перед обновлением состояния
      try {
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          userData: userData,
        );
      } catch (e) {
        debugPrint('❌ Ошибка при обновлении состояния AuthNotifier: $e');
        return;
      }

      // Если данных пользователя нет в локальном хранилище, запрашиваем их с сервера
      if (userData == null) {
        try {
          final requestService = ref.read(requestCodeProvider);
          final response = await requestService.userProfile();

          // Еще раз проверяем, что нотифаер активен
          try {
            if (response?.statusCode == 200 && response?.data != null) {
              // Сохраняем данные пользователя в локальном хранилище
              await StorageService.saveUserData(response?.data);
              state = state.copyWith(userData: response?.data);
            } else {
              // If profile fetch fails, log out
              await logout();
            }
          } catch (e) {
            debugPrint(
                '❌ Ошибка при обновлении состояния после получения профиля: $e');
          }
        } catch (e) {
          debugPrint('❌ Ошибка при получении профиля пользователя: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка в _initializeAuth: $e');
    }
  }

  bool get canAccessProfile {
    return state.isAuthenticated && state.userData != null;
  }

  Future<void> setToken(String token) async {
    try {
      // Clear cache before setting new token
      ApiClient().clearCache();

      // Сохраняем токен в локальном хранилище
      await StorageService.saveToken(token);

      // Устанавливаем токен в ApiClient
      ApiClient().token = token;

      try {
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
        );
      } catch (e) {
        debugPrint('❌ Ошибка при обновлении состояния в setToken: $e');
        return;
      }

      // Fetch user profile after setting token
      try {
        final requestService = ref.read(requestCodeProvider);
        final response = await requestService.userProfile();

        try {
          if (response?.statusCode == 200 && response?.data != null) {
            // Сохраняем данные пользователя в локальном хранилище
            await StorageService.saveUserData(response?.data);
            state = state.copyWith(userData: response?.data);
          } else {
            // If profile fetch fails, log out
            await logout();
          }
        } catch (e) {
          debugPrint(
              '❌ Ошибка при обновлении состояния после получения профиля в setToken: $e');
        }
      } catch (e) {
        debugPrint(
            '❌ Ошибка при получении профиля пользователя в setToken: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка в методе setToken: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Очищаем все данные авторизации через StorageService
      await StorageService.clearAuthData();

      // Очищаем токен в ApiClient
      ApiClient().token = null;

      // Clear API client's cache
      ApiClient().clearCache();

      try {
        state = AuthState(isAuthenticated: false);
      } catch (e) {
        debugPrint('❌ Ошибка при сбросе состояния в logout: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка в методе logout: $e');
    }
  }

  void updateUserData(Map<String, dynamic> userData) {
    try {
      // Сохраняем данные пользователя в локальном хранилище
      StorageService.saveUserData(userData);
      state = state.copyWith(userData: userData);
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении данных пользователя: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  debugPrint('🔄 Создание нового экземпляра AuthNotifier');
  final notifier = AuthNotifier(ref);

  // Добавляем обработчик для автоматического удаления
  ref.onDispose(() {
    debugPrint('🧹 Провайдер authProvider удален');
  });

  return notifier;
});
