import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  late Future<PackageInfo> _packageInfo;

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_not_available'.tr()),
          ),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(urlString);
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_error'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_error'.tr()),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    await BaseModal.show(
      context,
      title: 'modals.delete_profile.title'.tr(),
      message: 'modals.delete_profile.message'.tr(),
      buttons: [
        ModalButton(
          label: 'common.cancel'.tr(),
          type: ButtonType.normal,
          backgroundColor: AppColors.appBg,
          textColor: AppColors.secondary,
          onPressed: () => context.pop(),
        ),
        ModalButton(
          label: 'common.delete'.tr(),
          type: ButtonType.light,
          onPressed: () {
            _deleteProfile();
          },
        ),
      ],
    );
  }

  Future<void> _deleteProfile() async {
    try {
      final response =
          await ApiClient().dio.post('/api/aina/profile/deactivate');

      if (response.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        ApiClient().token = null;
        ApiClient().clearCache();

        try {
          ref.read(authProvider.notifier).logout();
        } catch (authError) {
          print('❌ Ошибка при вызове logout через authProvider: $authError');
        }

        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errors.delete_profile'.tr())),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
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
                        Consumer(
                          builder: (context, ref, child) {
                            final settingsAsync = ref.watch(settingsProvider);

                            return settingsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => Center(
                                child: Text('about.settings_error'.tr()),
                              ),
                              data: (settings) => Column(
                                children: [
                                  _buildLink('about.license_agreement'.tr(),
                                      () {
                                    _launchURL(settings.userAgreementFile?.url);
                                  }),
                                  _buildLink('about.public_offer'.tr(), () {
                                    _launchURL(settings.publicOfferFile?.url);
                                  }),
                                  _buildLink('about.privacy_policy'.tr(), () {
                                    _launchURL(settings
                                        .confidentialityAgreementFile?.url);
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (ref.watch(authProvider).isAuthenticated)
                      CustomButton(
                        label: 'about.delete_profile'.tr(),
                        isFullWidth: true,
                        type: ButtonType.bordered,
                        onPressed: _showDeleteConfirmation,
                      ),
                  ],
                ),
              ),
              CustomHeader(
                title: 'about.title'.tr(),
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
