import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';

class QrProcessingLoader extends StatelessWidget {
  const QrProcessingLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppColors.white,
              margin: const EdgeInsets.only(top: 64),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'qr.processing'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
