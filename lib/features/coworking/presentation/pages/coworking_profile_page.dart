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
import 'package:aina_flutter/core/widgets/communication_modal.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';

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
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      Future(() {
        if (mounted) {
          _refreshProfileData();
        }
      });
    }
  }

  Future<void> _refreshProfileData() async {
    if (!mounted) return;

    ref.invalidate(userProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(promenadeProfileProvider);
    ref.invalidate(profileCacheKeyProvider);

    Future(() {
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final ticketsAsync = ref.watch(userTicketsProvider);

    return userAsync.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: Center(
                    child: Text(
                      'profile.load_error'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
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
      ),
      data: (userData) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 64,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              color: AppColors.primary,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 0),
                              child: Row(
                                children: [
                                  AvatarEditWidget(
                                    avatarUrl: userData.avatarUrl,
                                    onAvatarPicked: _handleAvatarPicked,
                                    isLoading: _isLoading,
                                    temporaryImage: _temporaryAvatar,
                                    onAvatarRemoved: () async {
                                      setState(() {
                                        _isLoading = true;
                                        _temporaryAvatar = null;
                                      });
                                      try {
                                        final profileService =
                                            ref.read(promenadeProfileProvider);
                                        await profileService.removeAvatar();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'profile.settings.edit.avatar_removed'
                                                    .tr()),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'profile.settings.edit.avatar_error'
                                                    .tr()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${userData.firstName} ${userData.lastName}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userData.maskedPhone,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    'coworking.profile.personal_info'.tr(),
                                    Icons.chevron_right,
                                    backgroundColor: Colors.grey[200],
                                    onTap: () {
                                      context.pushNamed(
                                        'coworking_edit_data',
                                        pathParameters: {
                                          'id': widget.coworkingId.toString()
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  ticketsAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (tickets) {
                                      if (tickets.isNotEmpty) {
                                        return Column(
                                          children: [
                                            _buildMenuItem(
                                              'profile.coupons'.tr(),
                                              Icons.chevron_right,
                                              backgroundColor: Colors.grey[200],
                                              onTap: () {
                                                context.pushNamed(
                                                  'tickets',
                                                  pathParameters: {
                                                    'id': widget.coworkingId
                                                        .toString()
                                                  },
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
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
                                  // const SizedBox(height: 8),
                                  // _buildMenuItem(
                                  //   'coworking.profile.limit_accounts'.tr(),
                                  //   Icons.chevron_right,
                                  //   backgroundColor: Colors.grey[200],
                                  //   onTap: () {
                                  //     context.pushNamed(
                                  //       'coworking_limit_accounts',
                                  //       pathParameters: {
                                  //         'id': widget.coworkingId.toString()
                                  //       },
                                  //     );
                                  //   },
                                  // ),
                                  const SizedBox(height: 24),
                                  _buildMenuItem(
                                    'coworking.profile.contact_us'.tr(),
                                    Icons.chevron_right,
                                    backgroundColor: Colors.grey[200],
                                    onTap: () {
                                      final settingsAsync =
                                          ref.read(settingsProvider);
                                      settingsAsync.whenData((settings) {
                                        CommunicationModal.show(
                                          context,
                                          whatsappUrl:
                                              settings.whatsappLinkPromenade,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMenuItem(
                                    'coworking.profile.about_app'.tr(),
                                    Icons.chevron_right,
                                    backgroundColor: Colors.grey[200],
                                    onTap: () {
                                      context.pushNamed('about');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
      ),
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 64,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          height: 20,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          height: 16,
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.bgLight,
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
      ),
    );
  }
}
