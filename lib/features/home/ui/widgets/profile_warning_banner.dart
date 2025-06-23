import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:aina_flutter/app/styles/constants.dart';

class ProfileWarningBanner extends StatelessWidget {
  final VoidCallback? onEditProfileTap;

  const ProfileWarningBanner({
    super.key,
    this.onEditProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEditProfileTap,
      child: Container(
        margin: const EdgeInsets.only(
          left: AppLength.xs,
          right: AppLength.xs,
          top: 16,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgCom,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'profile.warning.incomplete'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'lib/app/assets/icons/linked-arrow.svg',
                  width: 24,
                  height: 24,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
