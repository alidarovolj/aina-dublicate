import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/widgets/communication_modal.dart';

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
  @override
  void initState() {
    super.initState();
    // Force refresh profile data when page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(userProvider);
    final settingsAsync = ref.watch(settingsProvider);

    // Show loading state while checking authentication
    if (authState.token == null) {
      return Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: _buildSkeletonLoader(context),
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

    // If not authenticated, redirect to login
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    return userAsync.when(
      loading: () => Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: _buildSkeletonLoader(context),
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
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Info Section
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                if (userData.avatarUrl != null)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Image.network(
                                      userData.avatarUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
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
                                          color: AppColors.primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userData.maskedPhone,
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
                          _buildMenuItem(
                            'coworking.profile.personal_info'.tr(),
                            Icons.chevron_right,
                            backgroundColor: Colors.grey[200],
                            onTap: () {
                              context.push(
                                  '/coworking/${widget.coworkingId}/profile/edit');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildMenuItem(
                            'coworking.profile.biometric'.tr(),
                            Icons.chevron_right,
                            backgroundColor: Colors.grey[200],
                            onTap: () {
                              context.push(
                                  '/coworking/${widget.coworkingId}/profile/biometric');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildMenuItem(
                            'coworking.profile.community_card'.tr(),
                            Icons.chevron_right,
                            backgroundColor: Colors.grey[200],
                            onTap: () {
                              context.push(
                                  '/coworking/${widget.coworkingId}/profile/community-card');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildMenuItem(
                            'coworking.profile.limit_accounts'.tr(),
                            Icons.chevron_right,
                            backgroundColor: Colors.grey[200],
                            onTap: () {
                              context.push(
                                  '/coworking/${widget.coworkingId}/profile/limit-accounts');
                            },
                          ),
                          const SizedBox(height: 32),

                          _buildMenuItem(
                            'coworking.profile.contact_us'.tr(),
                            Icons.chevron_right,
                            backgroundColor: Colors.grey[200],
                            onTap: () {
                              settingsAsync.whenData((settings) async {
                                CommunicationModal.show(
                                  context,
                                  whatsappUrl:
                                      settings.whatsappLinkAinaCoworking,
                                  onlyWhatsapp: false,
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
                    ],
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

  Widget _buildSkeletonLoader(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            // Profile Info Section Skeleton
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 30),
              child: Row(
                children: [
                  // Avatar skeleton
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name skeleton
                        Shimmer.fromColors(
                          baseColor: Colors.grey[100]!,
                          highlightColor: Colors.grey[300]!,
                          child: Container(
                            width: 200,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Phone number skeleton
                        Shimmer.fromColors(
                          baseColor: Colors.grey[100]!,
                          highlightColor: Colors.grey[300]!,
                          child: Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
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

            // Menu Items Skeleton
            ...List.generate(
              6, // Number of menu items
              (index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[100]!,
                  highlightColor: Colors.grey[300]!,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData? trailingIcon, {
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
