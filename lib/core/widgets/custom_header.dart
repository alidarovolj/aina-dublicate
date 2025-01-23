import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum HeaderType {
  pop,
  close,
}

class CustomHeader extends StatelessWidget {
  final String title;
  final HeaderType type;

  const CustomHeader({
    super.key,
    required this.title,
    this.type = HeaderType.close,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppLength.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (type == HeaderType.pop)
            GestureDetector(
              onTap: () => context.pop(),
              child: Transform.scale(
                scaleX: -1,
                child: SvgPicture.asset(
                  'lib/core/assets/icons/chevron-right.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          if (type == HeaderType.pop) const SizedBox(width: AppLength.sm),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lora(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          if (type == HeaderType.close)
            GestureDetector(
              onTap: () => context.go('/'),
              child: SvgPicture.asset(
                'lib/core/assets/icons/close.svg',
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
