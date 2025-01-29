import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  final int mallId;

  const ProfilePage({
    super.key,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    // Show loading state while checking authentication
    if (userAsync.token == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, redirect to malls
    if (!userAsync.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/malls');
      });
      return const SizedBox.shrink();
    }

    // If no user data, show error state
    if (userAsync.userData == null) {
      return Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: const Center(
                    child: Text(
                      'Не удалось загрузить данные профиля',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const CustomHeader(
                  title: "Профиль ТРЦ",
                  type: HeaderType.close,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userData = UserProfile.fromJson(userAsync.userData!);

    return Scaffold(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Персональная информация',
                          Icons.chevron_right,
                          backgroundColor: Colors.grey[200],
                          onTap: () {
                            context.pushNamed(
                              'mall_edit',
                              pathParameters: {'id': mallId.toString()},
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // _buildMenuItem(
                        //   'Связаться с нами',
                        //   null, // No chevron for this item
                        //   backgroundColor: Colors.grey[200],
                        //   onTap: () {},
                        // ),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          'О приложении',
                          Icons.chevron_right,
                          backgroundColor: Colors.grey[200],
                          onTap: () {
                            context.pushNamed('about');
                          },
                        ),
                      ],
                    ),

                    // Switch Account Section
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 28, right: 12, left: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Переключить на профиль Aina Coworking',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 24,
                              width: 44,
                              child: Switch.adaptive(
                                value: false,
                                onChanged: (value) {
                                  // TODO: Implement profile switch
                                },
                                activeColor: AppColors.white,
                                activeTrackColor: AppColors.primary,
                                inactiveThumbColor: AppColors.white,
                                inactiveTrackColor: AppColors.grey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const CustomHeader(
                title: "Профиль ТРЦ",
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  Icon(
                    trailingIcon,
                    color: Colors.grey,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
