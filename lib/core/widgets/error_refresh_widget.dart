import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorRefreshWidget extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? errorMessage;
  final String? refreshText;
  final IconData? icon;
  final bool isCompact;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isServerError;
  final Color? errorColor;

  const ErrorRefreshWidget({
    Key? key,
    required this.onRefresh,
    this.errorMessage,
    this.refreshText,
    this.icon,
    this.isCompact = false,
    this.backgroundColor,
    this.textColor,
    this.isServerError = false,
    this.errorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompactLayout() : _buildFullLayout();
  }

  Widget _buildFullLayout() {
    final Color iconColor =
        isServerError ? (errorColor ?? Colors.red[300]!) : Colors.grey[400]!;

    final Color messageColor = isServerError
        ? (errorColor ?? Colors.red[200]!)
        : (textColor ?? AppColors.textDarkGrey);

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
              icon ?? (isServerError ? Icons.error : Icons.error_outline),
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),

            // Сообщение об ошибке
            Text(
              errorMessage ?? 'common.error_loading_data'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: messageColor,
                fontWeight: isServerError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка обновления
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isServerError
                    ? (errorColor ?? Colors.red[600])
                    : AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                  color: textColor != null
                      ? textColor!.withOpacity(0.7)
                      : Colors.grey[600],
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
    final Color iconColor = isServerError
        ? (errorColor ?? Colors.red[300]!)
        : (textColor ?? Colors.grey[400]!);

    final Color messageColor = isServerError
        ? (errorColor ?? Colors.red[700]!)
        : (textColor ?? AppColors.textDarkGrey);

    final Color buttonColor = isServerError
        ? (errorColor ?? Colors.red[600]!)
        : (textColor ?? AppColors.primary);

    // Получаем текст кнопки
    final buttonText = refreshText ?? 'common.refresh'.tr();

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка ошибки
          Icon(
            icon ?? (isServerError ? Icons.error : Icons.error_outline),
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
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),

          // Кнопка обновления
          ElevatedButton(
            onPressed: onRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              minimumSize: const Size(100, 40),
              elevation: 4,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
