import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';

class CommunityDetailsModal extends StatelessWidget {
  final CommunityCard user;

  const CommunityDetailsModal({
    super.key,
    required this.user,
  });

  static void show(BuildContext context, {required CommunityCard user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityDetailsModal(user: user),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BaseSnackBar.show(
        context,
        message: 'community.copied'.tr(),
        type: SnackBarType.neutral,
      );
    });
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Upper block with avatar and name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.black,
            child: Row(
              children: [
                if (user.avatar?.url != null && user.avatar!.url.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(user.avatar!.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset(
                      'lib/app/assets/icons/plain_user.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (user.position != null) const SizedBox(height: 4),
                      if (user.position != null)
                        Text(
                          user.position!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  children: [
                    // Social links
                    if ((user.whatsapp != null &&
                            user.whatsapp!.numeric.isNotEmpty) ||
                        (user.telegram != null && user.telegram!.isNotEmpty) ||
                        (user.linkedin != null && user.linkedin!.isNotEmpty))
                      Row(
                        children: [
                          if (user.whatsapp != null &&
                              user.whatsapp!.numeric.isNotEmpty)
                            Expanded(
                              child: InkWell(
                                onTap: () => _launchUrl(
                                    'https://api.whatsapp.com/send?phone=${user.whatsapp!.numeric}'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.almostBlack,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SvgPicture.asset(
                                    'lib/app/assets/icons/white-socials/whatsapp.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (user.telegram != null &&
                              user.telegram!.isNotEmpty) ...[
                            if (user.whatsapp != null &&
                                user.whatsapp!.numeric.isNotEmpty)
                              const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _launchUrl(user.telegram!),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.almostBlack,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SvgPicture.asset(
                                    'lib/app/assets/icons/white-socials/telegram.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (user.linkedin != null &&
                              user.linkedin!.isNotEmpty) ...[
                            if ((user.whatsapp != null &&
                                    user.whatsapp!.numeric.isNotEmpty) ||
                                (user.telegram != null &&
                                    user.telegram!.isNotEmpty))
                              const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _launchUrl(user.linkedin!),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.almostBlack,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SvgPicture.asset(
                                    'lib/app/assets/icons/white-socials/linkedin.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Contact info
                    if ((user.phone != null &&
                            user.phone!.numeric.isNotEmpty) ||
                        (user.email != null && user.email!.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          children: [
                            if (user.phone != null &&
                                user.phone!.numeric.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'community.card.phone_label'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.darkGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () => _launchUrl(
                                              'tel:${user.phone!.numeric}'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            user.phone!.masked,
                                            style: const TextStyle(
                                              color: AppColors.blueGrey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _copyToClipboard(
                                              context, user.phone!.numeric),
                                          icon: SvgPicture.asset(
                                            'lib/app/assets/icons/copy.svg',
                                            width: 24,
                                            height: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (user.email != null && user.email!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'community.card.email_label'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.darkGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () => _launchUrl(
                                              'mailto:${user.email}'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            user.email!,
                                            style: const TextStyle(
                                              color: AppColors.blueGrey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _copyToClipboard(
                                              context, user.email!),
                                          icon: SvgPicture.asset(
                                            'lib/app/assets/icons/copy.svg',
                                            width: 24,
                                            height: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Additional info blocks
                    if ((user.info != null && user.info!.isNotEmpty) ||
                        (user.company != null && user.company!.isNotEmpty) ||
                        (user.textTitle != null && user.textTitle!.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Column(
                          children: [
                            if (user.info != null && user.info!.isNotEmpty)
                              _buildInfoBlock(
                                'personal',
                                'community.card.personal_info'.tr(),
                                user.info!,
                              ),
                            if (user.company != null &&
                                user.company!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildWorkBlock(
                                user.company!,
                                user.employment,
                              ),
                            ],
                            if (user.textTitle != null &&
                                user.textTitle!.isNotEmpty &&
                                user.textContent != null &&
                                user.textContent!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildInfoBlock(
                                'personal',
                                user.textTitle!,
                                user.textContent!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (user.image?.url != null &&
                        user.image!.url.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          user.image!.url,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                    if (user.buttonTitle != null &&
                        user.buttonTitle!.isNotEmpty &&
                        user.buttonLink != null &&
                        user.buttonLink!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () => _launchUrl(user.buttonLink!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.buttonTitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'lib/app/assets/icons/info/$icon.svg',
          width: 25,
          height: 25,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.almostBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDarkGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkBlock(String company, String? employment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'lib/app/assets/icons/info/work.svg',
          width: 25,
          height: 25,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'community.card.company_label'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.almostBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'community.card.contacts.company'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.almostBlack,
                    ),
                  ),
                  if (employment != null)
                    Text(
                      'community.card.employment.$employment'
                          .tr()
                          .toLowerCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
