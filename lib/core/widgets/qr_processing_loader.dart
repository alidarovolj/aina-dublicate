import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';

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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Ожидайте, идет проверка условий акции.',
                      style: TextStyle(
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
