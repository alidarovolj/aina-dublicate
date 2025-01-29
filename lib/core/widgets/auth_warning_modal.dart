import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';

class AuthWarningModal {
  static Future<void> show(
    BuildContext context, {
    bool isProfileIncomplete = false,
    String? mallId,
    String? promotionId,
  }) {
    return BaseModal.show(
      context,
      message: isProfileIncomplete
          ? 'Перед сканированием чека, пожалуйста, убедитесь в правильности имени и фамилии в профиле. Это обязательное условие участия в акции.'
          : 'Для участия в акции необходимо авторизоваться',
      buttons: [
        ModalButton(
          label: 'В профиль',
          onPressed: () {
            if (mallId != null) {
              try {
                final parsedMallId = int.parse(mallId);
                context.go('/malls/$parsedMallId/profile');
              } catch (e) {
                debugPrint('Invalid mall ID format: $mallId');
              }
            } else {
              context.go('/malls/1/profile');
            }
          },
          textColor: AppColors.secondary,
          backgroundColor: Colors.white,
        ),
        ModalButton(
          label: 'Сканировать',
          type: ButtonType.light,
          onPressed: () {
            context.go('/malls/$mallId/promotions/$promotionId/qr');
          },
        ),
      ],
    );
  }
}
