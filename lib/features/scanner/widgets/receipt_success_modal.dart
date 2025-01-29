import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';

class ReceiptSuccessModal {
  static Future<void> show(
    BuildContext context, {
    required double amount,
    required List<int> tickets,
    required String mallId,
  }) {
    return BaseModal.show(
      context,
      title: 'Ваш чек зарегистрирован. Поздравляем!',
      message:
          'Номера купонов для участия в розыгрыше: ${tickets.join(", ")}\n\nНомер хранится в профиле, в разделе «Купоны».',
      width: MediaQuery.of(context).size.width,
      buttons: [
        ModalButton(
          label: 'Назад к акции',
          onPressed: () {
            context.go('/malls/$mallId/promotions');
          },
          textColor: AppColors.secondary,
          backgroundColor: Colors.white,
        ),
        ModalButton(
          label: 'В профиль',
          type: ButtonType.light,
          onPressed: () {
            context.go('/malls/$mallId/profile');
          },
        ),
      ],
    );
  }
}
