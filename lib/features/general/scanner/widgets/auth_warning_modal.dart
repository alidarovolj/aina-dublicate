import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';

class AuthWarningModal {
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

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
          ? 'auth.warning.profile_incomplete_message'.tr()
          : 'auth.warning.auth_required_message'.tr(),
      buttons: isProfileIncomplete
          ? [
              ModalButton(
                label: 'auth.warning.to_profile'.tr(),
                onPressed: () async {
                  if (mallId == null || mallId.isEmpty) {
                    showError(context, 'errors.mall_id_not_found'.tr());
                    return;
                  }

                  final container = ProviderScope.containerOf(context);
                  final buildingsAsync = container.read(buildingsProvider);

                  final buildingsData = buildingsAsync.value;
                  if (buildingsData == null) {
                    showError(
                        context, 'errors.buildings_data_unavailable'.tr());
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
                    context.push('/coworking/$mallId/profile');
                  } else {
                    context.pushNamed('mall_profile',
                        pathParameters: {'id': mallId});
                  }
                },
                textColor: AppColors.secondary,
                backgroundColor: Colors.white,
              ),
              ModalButton(
                label: 'auth.warning.scan'.tr(),
                type: ButtonType.light,
                onPressed: () async {
                  AmplitudeService().logEvent(
                    'scan_verification_click',
                    eventProperties: {
                      'Platform': _getPlatform(),
                    },
                  );

                  if (mallId == null || mallId.isEmpty) {
                    showError(context, 'errors.mall_id_not_found'.tr());
                    return;
                  }

                  if (promotionId == null || promotionId.isEmpty) {
                    showError(context, 'errors.promotion_id_not_found'.tr());
                    return;
                  }

                  final container = ProviderScope.containerOf(context);
                  final buildingsAsync = container.read(buildingsProvider);

                  final buildingsData = buildingsAsync.value;
                  if (buildingsData == null) {
                    showError(
                        context, 'errors.buildings_data_unavailable'.tr());
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
