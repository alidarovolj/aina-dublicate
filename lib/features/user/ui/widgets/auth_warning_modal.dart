import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart';

/// AuthWarningModal - Утилита для проверки авторизации и доступа к QR функциям
///
/// Основные методы:
/// 1. `show()` - Показывает модальное окно с предупреждением об авторизации или неполном профиле
/// 2. `checkAuthAndNavigateToQR()` - Полная проверка и навигация к QR сканеру
///
/// Примеры использования:
///
/// ```dart
/// // Простая проверка авторизации
/// AuthWarningModal.show(context, promotionId: '123', mallId: '1');
///
/// // Полная проверка с навигацией к QR сканеру
/// await AuthWarningModal.checkAuthAndNavigateToQR(
///   context,
///   ref,
///   promotionId: '123',
///   mallId: '1',
/// );
///
/// // Использование в onTap промоакции
/// onTap: () async {
///   await AuthWarningModal.checkAuthAndNavigateToQR(
///     context,
///     ref,
///     promotionId: promotion.id.toString(),
///     mallId: promotion.building?.id.toString() ?? '1',
///   );
/// }
/// ```
class AuthWarningModal {
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Прямая навигация на QR сканер
  static void _navigateToQrScanner(
      BuildContext context, String promotionId, String mallId) {
    // Логируем событие
    AmplitudeService().logEvent(
      'scan_direct_navigation',
      eventProperties: {
        'Platform': _getPlatform(),
      },
    );

    // Переходим на экран QR сканера
    context.pushNamed(
      'promotion_qr',
      pathParameters: {
        'promotionId': promotionId,
      },
      queryParameters: {
        'mallId': mallId,
      },
    );
  }

  /// Проверяет авторизацию и профиль, затем навигирует к QR сканеру или показывает предупреждение
  static Future<void> checkAuthAndNavigateToQR(
    BuildContext context,
    WidgetRef ref, {
    required String promotionId,
    required String mallId,
  }) async {
    try {
      // Проверяем авторизацию
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        // Пользователь не авторизован, показываем модальное окно авторизации
        await show(
          context,
          promotionId: promotionId,
          mallId: mallId,
        );
        return;
      }

      // Пользователь авторизован, делаем запрос на получение профиля
      final profileService = ref.read(promenadeProfileProvider);
      final profileData = await profileService.getProfile(forceRefresh: true);

      // Проверяем наличие имени и фамилии
      final firstName = profileData['firstname'];
      final lastName = profileData['lastname'];

      final hasNameInfo = firstName != null &&
          firstName.toString().trim().isNotEmpty &&
          lastName != null &&
          lastName.toString().trim().isNotEmpty;

      if (hasNameInfo) {
        // Имя и фамилия указаны, переходим сразу к QR-сканеру
        if (context.mounted) {
          _navigateToQrScanner(context, promotionId, mallId);
        }
      } else {
        // Имя или фамилия не указаны, показываем предупреждение
        if (context.mounted) {
          await show(
            context,
            isProfileIncomplete: true,
            promotionId: promotionId,
            mallId: mallId,
          );
        }
      }
    } catch (e) {
      // Обработка ошибок, включая 401 (Unauthorized)
      if (e.toString().contains('401')) {
        if (context.mounted) {
          await show(
            context,
            promotionId: promotionId,
            mallId: mallId,
          );
        }
      } else {
        // Другая ошибка при получении профиля
        if (context.mounted) {
          BaseSnackBar.show(
            context,
            message: 'common.error.general'.tr(),
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  static Future<void> show(
    BuildContext context, {
    bool isProfileIncomplete = false,
    String? mallId,
    String? promotionId,
  }) {
    void showError(BuildContext context, String message) {
      BaseSnackBar.show(
        context,
        message: message,
        type: SnackBarType.error,
      );
    }

    // Validate parameters
    if (mallId == null || promotionId == null) {
      debugPrint('⚠️ AuthWarningModal: mallId или promotionId отсутствуют');
      return Future.value();
    }

    // Если неполный профиль, показываем соответствующую модалку
    if (isProfileIncomplete) {
      return BaseModal.show(
        context,
        message: 'auth.warning.profile_incomplete_message'.tr(),
        buttons: [
          ModalButton(
            label: 'auth.warning.to_profile'.tr(),
            onPressed: () {
              final container = ProviderScope.containerOf(context);
              final buildingsAsync = container.read(buildingsProvider);
              final buildingsData = buildingsAsync.value;

              if (buildingsData == null) {
                showError(context, 'errors.buildings_data_unavailable'.tr());
                return;
              }

              final buildings = [
                ...buildingsData['mall'] ?? [],
                ...buildingsData['coworking'] ?? []
              ];

              final building = buildings.firstWhere(
                (b) => b.id.toString() == mallId,
                orElse: () => buildings.first,
              );

              if (building.type == 'coworking') {
                context.pushReplacement('/coworking/$mallId/profile');
              } else {
                context.pushReplacementNamed('mall_profile',
                    pathParameters: {'id': mallId});
              }
            },
            type: ButtonType.light,
          ),
        ],
      );
    }

    // Нет авторизации, показываем модалку входа
    return BaseModal.show(
      context,
      message: 'auth.warning.auth_required_message'.tr(),
      buttons: [
        ModalButton(
          label: 'auth.warning.login'.tr(),
          type: ButtonType.light,
          onPressed: () {
            context.push('/login');
          },
        ),
      ],
    );
  }
}
