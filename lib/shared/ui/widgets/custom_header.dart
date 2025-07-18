import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum HeaderType {
  pop,
  close,
  back,
  none,
}

class CustomHeader extends StatelessWidget {
  final String title;
  final HeaderType type;
  final bool isDark;
  final VoidCallback? onBack;
  final Widget? trailing;

  const CustomHeader({
    super.key,
    required this.title,
    this.type = HeaderType.close,
    this.isDark = false,
    this.onBack,
    this.trailing,
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
              onTap: () {
                if (onBack != null) {
                  onBack!();
                } else if (Navigator.canPop(context)) {
                  context.pop();
                }
              },
              child: Transform.scale(
                scaleX: -1,
                child: SvgPicture.asset(
                  'lib/app/assets/icons/chevron-right.svg',
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
              style: GoogleFonts.lora(fontSize: 22, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
          if (trailing != null) trailing!,
          if (type == HeaderType.close)
            GestureDetector(
              onTap: () => context.go('/home'),
              child: SvgPicture.asset(
                'lib/app/assets/icons/close.svg',
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
