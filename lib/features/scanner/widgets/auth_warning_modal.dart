import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';

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
                    showError(context, 'Ошибка: ID здания не найден');
                    return;
                  }

                  final container = ProviderScope.containerOf(context);
                  final buildingsAsync = container.read(buildingsProvider);

                  final buildingsData = buildingsAsync.value;
                  if (buildingsData == null) {
                    showError(context, 'Ошибка: Данные зданий недоступны');
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
                    context.go('/coworking/$mallId/profile');
                  } else {
                    context.pushNamed('mall_profile',
                        pathParameters: {'id': mallId});
                  }
                },
                textColor: AppColors.secondary,
                backgroundColor: Colors.white,
              ),
              ModalButton(
                label: 'Сканировать',
                type: ButtonType.light,
                onPressed: () async {
                  if (mallId == null || mallId.isEmpty) {
                    showError(context, 'Ошибка: ID здания не найден');
                    return;
                  }

                  if (promotionId == null || promotionId.isEmpty) {
                    showError(context, 'Ошибка: ID акции не найден');
                    return;
                  }

                  final container = ProviderScope.containerOf(context);
                  final buildingsAsync = container.read(buildingsProvider);

                  final buildingsData = buildingsAsync.value;
                  if (buildingsData == null) {
                    showError(context, 'Ошибка: Данные зданий недоступны');
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

                  context.pushNamed(
                    'promotion_qr',
                    pathParameters: {
                      'promotionId': promotionId,
                    },
                    queryParameters: {
                      'mallId': mallId,
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
