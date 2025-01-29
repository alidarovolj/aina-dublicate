import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';

class UpperHeader extends StatelessWidget {
  const UpperHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: AppLength.xxl),
          color: AppColors.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppLength.xl),
                child: Image.asset(
                  'lib/core/assets/images/logos/text.png',
                  height: 17,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
