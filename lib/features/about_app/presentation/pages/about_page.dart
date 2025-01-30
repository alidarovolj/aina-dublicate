import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  late Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.backgroundDark,
                margin: const EdgeInsets.only(top: 64),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 56),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // Logo and version
                        Center(
                          child: SvgPicture.asset(
                            'lib/core/assets/images/profile-logo-white.svg',
                            width: 200,
                          ),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        FutureBuilder<PackageInfo>(
                          future: _packageInfo,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Center(
                                child: Text(
                                  'about.version'
                                      .tr(args: [snapshot.data!.version]),
                                  style: const TextStyle(
                                    fontSize: AppLength.body,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        Center(
                          child: Text(
                            'about.company'.tr(),
                            style: const TextStyle(
                              fontSize: AppLength.body,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        // Links
                        _buildLink('about.license_agreement'.tr(), () {
                          // Handle license agreement tap
                        }),
                        _buildLink('about.public_offer'.tr(), () {
                          // Handle public offer tap
                        }),
                        _buildLink('about.privacy_policy'.tr(), () {
                          // Handle privacy policy tap
                        }),
                      ],
                    ),
                    CustomButton(
                      label: 'about.delete_profile'.tr(),
                      isFullWidth: true,
                      type: ButtonType.bordered,
                      onPressed: () {
                        // Handle profile deletion
                      },
                    ),
                  ],
                ),
              ),
              const CustomHeader(
                title: "О приложении",
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppLength.body,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
