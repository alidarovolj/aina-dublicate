import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SimpleAuthWarningModal {
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Показ модального окна с предупреждением о необходимости авторизации
  static Future<void> show(BuildContext context) {
    // Логируем событие
    AmplitudeService().logEvent(
      'auth_warning_shown',
      eventProperties: {
        'Platform': _getPlatform(),
        'Feature': 'qr_scan',
      },
    );

    // Показываем модалку входа
    return BaseModal.show(
      context,
      message: 'auth_qr.auth_required'.tr(),
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
