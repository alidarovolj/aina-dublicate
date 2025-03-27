import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/base_modal.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ReceiptSuccessModal {
  static Future<void> show(
    BuildContext context, {
    required double amount,
    required List<int> tickets,
    required String mallId,
  }) {
    return BaseModal.show(
      context,
      title: 'scanner.receipt_success_title'.tr(),
      message: 'scanner.receipt_success_message'.tr(args: [tickets.join(", ")]),
      width: MediaQuery.of(context).size.width,
      buttons: [
        ModalButton(
          label: 'scanner.back_to_promotions'.tr(),
          onPressed: () {
            context.push('/malls/$mallId/promotions');
          },
          textColor: AppColors.secondary,
          backgroundColor: Colors.white,
        ),
        ModalButton(
          label: 'scanner.to_profile'.tr(),
          type: ButtonType.light,
          onPressed: () {
            context.push('/malls/$mallId/profile');
          },
        ),
      ],
    );
  }
}
