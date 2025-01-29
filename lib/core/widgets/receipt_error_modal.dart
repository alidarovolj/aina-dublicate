import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';

class ReceiptErrorModal {
  static Future<void> show(
    BuildContext context, {
    required String message,
    required String mallId,
  }) {
    return BaseModal.show(
      context,
      title: 'Ошибка',
      message: message,
      buttons: [
        ModalButton(
          label: 'Назад к акциям',
          onPressed: () {
            context.go('/malls/$mallId/promotions');
          },
          textColor: AppColors.secondary,
          backgroundColor: Colors.white,
        ),
        const ModalButton(
          label: 'Сканировать снова',
          type: ButtonType.light,
        ),
      ],
    );
  }
}
