import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorRefreshWidget extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? errorMessage;
  final String? refreshText;
  final IconData? icon;
  final bool isCompact;
  final bool isServerError;
  final double? height;

  const ErrorRefreshWidget({
    super.key,
    required this.onRefresh,
    this.errorMessage,
    this.refreshText,
    this.icon,
    this.isCompact = false,
    this.isServerError = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(
        horizontal: AppLength.xs,
        vertical: AppLength.xs,
      ),
      decoration: BoxDecoration(
          color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
      child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
    );
  }

  Widget _buildFullLayout() {
    const Color iconColor = Colors.red;
    final Color messageColor = Colors.red.shade900;
    const Color buttonColor = Colors.red;

    // Получаем текст кнопки и текст подсказки
    final buttonText = 'common.refresh'.tr();
    final hintText = refreshText ?? 'common.tap_to_refresh'.tr();

    // Проверяем, совпадают ли тексты
    final showHintText =
        hintText != buttonText && refreshText != 'common.refresh'.tr();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка ошибки
            Icon(
              icon ?? Icons.warning_amber_rounded,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 16),

            // Сообщение об ошибке
            Text(
              errorMessage ?? 'common.error_loading_data'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: messageColor,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),

            // Кнопка обновления
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Текст подсказки (только если он отличается от текста кнопки)
            if (showHintText) ...[
              const SizedBox(height: 12),
              Text(
                hintText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: messageColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    const Color iconColor = Colors.red;
    final Color messageColor = Colors.red.shade900;
    const Color buttonColor = Colors.red;

    // Получаем текст кнопки
    final buttonText = refreshText ?? 'common.refresh'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка ошибки
          Icon(
            icon ?? Icons.warning_amber_rounded,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(width: 16),

          // Сокращенное сообщение об ошибке
          Expanded(
            child: Text(
              errorMessage ?? 'common.error_loading_data'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: messageColor,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),

          // Кнопка обновления
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
