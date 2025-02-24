import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart';
import 'dart:io';
import 'package:aina_flutter/core/widgets/avatar_edit_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class CoworkingProfilePage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingProfilePage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingProfilePage> createState() =>
      _CoworkingProfilePageState();
}

class _CoworkingProfilePageState extends ConsumerState<CoworkingProfilePage> {
  File? _temporaryAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileCacheKeyProvider.notifier).state++;
      }
    });
  }

  Future<void> _handleAvatarPicked(File photo) async {
    setState(() {
      _isLoading = true;
      _temporaryAvatar = photo;
    });

    try {
      final profileService = ref.read(promenadeProfileProvider);
      await profileService.uploadAvatar(photo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.settings.edit.avatar_updated'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _temporaryAvatar = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.settings.edit.avatar_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAvatarRemoved() async {
    setState(() => _isLoading = true);

    try {
      final profileService = ref.read(promenadeProfileProvider);
      await profileService.removeAvatar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.settings.edit.avatar_removed'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.settings.edit.avatar_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheKey = ref.watch(profileCacheKeyProvider);
    final profileAsync = ref.watch(promenadeProfileDataProvider(cacheKey));

    return profileAsync.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (profile) {
        final avatarUrl = profile['avatar']?['url'];
        final currentAvatarUrl = _temporaryAvatar != null ? null : avatarUrl;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 64),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration:
                                const BoxDecoration(color: AppColors.primary),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                AvatarEditWidget(
                                  avatarUrl: currentAvatarUrl,
                                  temporaryImage: _temporaryAvatar,
                                  onAvatarPicked: _handleAvatarPicked,
                                  onAvatarRemoved: _handleAvatarRemoved,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile['phone']['masked'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Menu Items
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  'coworking.profile.personal_info'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () async {
                                    final result = await context.pushNamed(
                                      'coworking_edit_data',
                                      pathParameters: {
                                        'id': widget.coworkingId.toString()
                                      },
                                    );

                                    if (mounted) {
                                      // Clear cache and increment cache key to force refresh
                                      imageCache.clearLiveImages();
                                      imageCache.clear();
                                      ref
                                          .read(
                                              profileCacheKeyProvider.notifier)
                                          .state++;

                                      // Fetch profile with force refresh
                                      final profileService =
                                          ref.read(promenadeProfileProvider);
                                      await profileService.getProfile(
                                          forceRefresh: true);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildMenuItem(
                                  'coworking.profile.biometric'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () {
                                    context.pushNamed(
                                      'coworking_biometric',
                                      pathParameters: {
                                        'id': widget.coworkingId.toString()
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildMenuItem(
                                  'coworking.profile.community_card'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () {
                                    context.pushNamed(
                                      'community_card',
                                      pathParameters: {
                                        'id': widget.coworkingId.toString()
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildMenuItem(
                                  'coworking.profile.limit_accounts'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () {
                                    context.pushNamed(
                                      'coworking_limit_accounts',
                                      pathParameters: {
                                        'id': widget.coworkingId.toString()
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                _buildMenuItem(
                                  'profile.contact_us'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () {
                                    final settingsAsync =
                                        ref.read(settingsProvider);
                                    settingsAsync.whenData((settings) async {
                                      try {
                                        final decodedUrl = Uri.decodeFull(
                                                settings.whatsappLinkAinaMall)
                                            .replaceAll('%2B', '+')
                                            .replaceAll('%20', ' ');

                                        final whatsappUri =
                                            Uri.parse(decodedUrl.replaceAll(
                                          'https://api.whatsapp.com/send',
                                          'whatsapp://send',
                                        ));

                                        bool launched = false;
                                        try {
                                          launched = await launchUrl(
                                            whatsappUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } catch (_) {
                                          launched = false;
                                        }

                                        if (!launched) {
                                          final httpUri = Uri.parse(decodedUrl);
                                          launched = await launchUrl(
                                            httpUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }

                                        if (!launched && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'communication.modal.whatsapp.error'
                                                      .tr()),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'communication.modal.whatsapp.error'
                                                      .tr()),
                                            ),
                                          );
                                        }
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildMenuItem(
                                  'profile.about_app'.tr(),
                                  Icons.chevron_right,
                                  backgroundColor: Colors.grey[200],
                                  onTap: () {
                                    context.pushNamed('about');
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomHeader(
                    title: 'coworking.profile.title'.tr(),
                    type: HeaderType.close,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 64),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Avatar and user info skeleton
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 30),
                        child: Row(
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 20,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 16,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Menu items skeleton
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: List.generate(
                            6, // Number of menu items
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              CustomHeader(
                title: 'coworking.profile.title'.tr(),
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData? trailingIcon, {
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailingIcon != null)
                SvgPicture.asset(
                  'lib/core/assets/icons/chevron-right.svg',
                  width: 24,
                  height: 24,
                  color: AppColors.almostBlack,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
