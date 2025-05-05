import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';

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
