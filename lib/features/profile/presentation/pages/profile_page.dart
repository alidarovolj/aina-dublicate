import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

class ProfilePage extends ConsumerWidget {
  final int mallId;

  const ProfilePage({
    super.key,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
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
                child: ListView(
                  children: [
                    // Profile Info Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (userData.avatarUrl != null)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  NetworkImage(userData.avatarUrl!),
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
                        // TODO: Navigate to personal info
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      'Язык',
                      Icons.chevron_right,
                      backgroundColor: Colors.grey[200],
                      onTap: () {
                        // TODO: Navigate to language settings
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      'Связаться с нами',
                      null, // No chevron for this item
                      backgroundColor: Colors.grey[200],
                      onTap: () {
                        // TODO: Handle contact action
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      'О приложении',
                      Icons.chevron_right,
                      backgroundColor: Colors.grey[200],
                      onTap: () {
                        // TODO: Navigate to about app
                      },
                    ),

                    // Switch Account Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Переключить на профиль Aina Coworking',
                                style: TextStyle(
                                  fontSize: 16,
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
    bool showDivider = false,
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
