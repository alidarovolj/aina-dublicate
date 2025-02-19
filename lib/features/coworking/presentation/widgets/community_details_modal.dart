import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';

class CommunityDetailsModal extends StatelessWidget {
  final CommunityCard user;

  const CommunityDetailsModal({
    super.key,
    required this.user,
  });

  static Future<void> show(
    BuildContext context, {
    required CommunityCard user,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return CommunityDetailsModal(user: user);
            },
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community.copied'.tr())),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upper block with avatar and name
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(
                              user.avatar?.url ??
                                  'https://ionicframework.com/docs/img/demos/avatar.svg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (user.position != null)
                              Text(
                                user.position!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Lower block with details
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Social media buttons
                        if (user.whatsapp != null ||
                            user.telegram != null ||
                            user.linkedin != null)
                          Row(
                            children: [
                              if (user.whatsapp != null)
                                Expanded(
                                  child: _SocialButton(
                                    icon:
                                        'lib/core/assets/icons/white-socials/whatsapp.svg',
                                    onTap: () => _launchUrl(
                                        'https://api.whatsapp.com/send?phone=${user.whatsapp!.numeric}'),
                                  ),
                                ),
                              if (user.telegram != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    icon:
                                        'lib/core/assets/icons/white-socials/telegram.svg',
                                    onTap: () => _launchUrl(user.telegram
                                            is String
                                        ? user.telegram as String
                                        : 'https://t.me/${(user.telegram as PhoneNumber).numeric}'),
                                  ),
                                ),
                              ],
                              if (user.linkedin != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    icon:
                                        'lib/core/assets/icons/white-socials/linkedin.svg',
                                    onTap: () => _launchUrl(user.linkedin!),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Contact information
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.phone != null)
                                _ContactItem(
                                  label: 'community.card.phone_label'.tr(),
                                  value: user.phone!.masked,
                                  onCopy: () => _copyToClipboard(
                                      context, user.phone!.numeric),
                                  onTap: () =>
                                      _launchUrl('tel:${user.phone!.numeric}'),
                                ),
                              if (user.email != null)
                                _ContactItem(
                                  label: 'community.card.email_label'.tr(),
                                  value: user.email!,
                                  onCopy: () =>
                                      _copyToClipboard(context, user.email!),
                                  onTap: () =>
                                      _launchUrl('mailto:${user.email}'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Additional information
                        if (user.info != null)
                          _InfoBlock(
                            icon: 'lib/core/assets/icons/info/personal.svg',
                            title: 'community.card.personal_info'.tr(),
                            content: user.info!,
                          ),
                        if (user.company != null) ...[
                          const SizedBox(height: 24),
                          _InfoBlock(
                            icon: 'lib/core/assets/icons/info/work.svg',
                            title: 'community.card.work'.tr(),
                            content: user.company!,
                            employment: user.employment,
                          ),
                        ],
                        if (user.textTitle != null &&
                            user.textContent != null) ...[
                          const SizedBox(height: 24),
                          _InfoBlock(
                            icon: 'lib/core/assets/icons/info/personal.svg',
                            title: user.textTitle!,
                            content: user.textContent!,
                          ),
                        ],
                        if (user.image?.url != null) ...[
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              user.image!.url,
                              width: double.infinity,
                              height: 350,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        if (user.buttonTitle != null &&
                            user.buttonLink != null) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _launchUrl(user.buttonLink!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                user.buttonTitle!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final VoidCallback onTap;

  const _ContactItem({
    required this.label,
    required this.value,
    required this.onCopy,
    required this.onTap,
  });

  Future<void> _handleCopy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('community.copied'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withOpacity(0.8),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
          ),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _handleCopy(context),
              child: SvgPicture.asset(
                'lib/core/assets/icons/copy.svg',
                width: 24,
                height: 24,
                colorFilter:
                    const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String icon;
  final String title;
  final String content;
  final String? employment;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.content,
    this.employment,
  });

  String _getEmploymentText(String employment) {
    switch (employment) {
      case 'CONTRACT':
        return 'community.card.employment.contract'.tr();
      case 'CASUAL':
        return 'community.card.employment.casual'.tr();
      case 'FULL_TIME':
        return 'community.card.employment.full_time'.tr();
      case 'PART_TIME':
        return 'community.card.employment.part_time'.tr();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (employment != null) ...[
                Text(
                  'community.card.company_label'.tr(),
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _getEmploymentText(employment!).toLowerCase(),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textDarkGrey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
