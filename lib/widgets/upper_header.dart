import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/language_switcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                child: SvgPicture.asset(
                  'lib/app/assets/images/logo-short.svg',
                  height: 17,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: AppLength.xl),
                child: const LanguageSwitcher(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
