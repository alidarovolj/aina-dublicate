import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final String? buttonTitle;
  final VoidCallback? onButtonPressed;
  final String? leadingIcon;

  const SectionWidget({
    super.key,
    required this.title,
    required this.child,
    this.buttonTitle,
    this.onButtonPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppLength.xs, right: AppLength.xs, bottom: AppLength.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (leadingIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: SvgPicture.asset(
                        leadingIcon!,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                        placeholderBuilder: (context) => const Icon(
                          Icons.error,
                          size: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppLength.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (buttonTitle != null && onButtonPressed != null)
                Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: onButtonPressed,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppLength.xs,
                                vertical: AppLength.tiny),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  buttonTitle!,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: AppLength.xs),
                          child: Icon(
                            Icons.arrow_forward_ios_outlined,
                            color: AppColors.primary,
                            size: AppLength.xs,
                          ),
                        ),
                      ],
                    ))
            ],
          ),
        ),
        child,
      ],
    );
  }
}
