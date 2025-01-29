import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';

class AuthWarningModal {
  static Future<void> show(
    BuildContext context, {
    bool isProfileIncomplete = false,
    String? mallId,
    String? promotionId,
  }) {
    void showError(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return BaseModal.show(
      context,
      message: isProfileIncomplete
          ? 'Перед сканированием чека, пожалуйста, убедитесь в правильности имени и фамилии в профиле. Это обязательное условие участия в акции.'
          : 'Для участия в акции необходимо авторизоваться',
      buttons: isProfileIncomplete
          ? [
              ModalButton(
                label: 'В профиль',
                onPressed: () async {
                  if (mallId == null || mallId.isEmpty) {
                    showError(context, 'Ошибка: ID торгового центра не найден');
                    return;
                  }
                  context.go('/malls/$mallId/profile');
                },
                textColor: AppColors.secondary,
                backgroundColor: Colors.white,
              ),
              ModalButton(
                label: 'Сканировать',
                type: ButtonType.light,
                onPressed: () {
                  if (mallId == null || mallId.isEmpty) {
                    showError(context, 'Ошибка: ID торгового центра не найден');
                    return;
                  }

                  if (promotionId == null || promotionId.isEmpty) {
                    showError(context, 'Ошибка: ID акции не найден');
                    return;
                  }

                  // Get ProviderContainer
                  final container = ProviderScope.containerOf(context);
                  final userProfileAsync = container.read(userProvider);

                  userProfileAsync.when(
                    data: (userProfile) {
                      if (userProfile.firstName.isEmpty ||
                          userProfile.lastName.isEmpty) {
                        showError(context,
                            'Пожалуйста, заполните имя и фамилию в профиле');
                        return;
                      }
                      context.go('/malls/$mallId/promotions/$promotionId/qr');
                    },
                    loading: () {
                      showError(context, 'Загрузка данных профиля...');
                    },
                    error: (error, stack) {
                      showError(context, 'Ошибка при загрузке данных профиля');
                    },
                  );
                },
              ),
            ]
          : [
              ModalButton(
                label: 'Авторизоваться',
                type: ButtonType.light,
                onPressed: () {
                  context.go('/login');
                },
              ),
            ],
    );
  }
}
