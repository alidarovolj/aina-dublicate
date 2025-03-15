import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isFullScreen;

  const NoInternetWidget({
    super.key,
    required this.onRefresh,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    return isFullScreen
        ? _buildFullScreenLayout(context)
        : _buildModalLayout(context);
  }

  Widget _buildFullScreenLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildModalLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Изображение ошибки
            Image.asset(
              'lib/core/assets/images/no-connection.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            // Заголовок ошибки
            Text(
              'common.no_internet.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Сообщение об ошибке
            Text(
              'common.no_internet.message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка обновления
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'common.no_internet.button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
