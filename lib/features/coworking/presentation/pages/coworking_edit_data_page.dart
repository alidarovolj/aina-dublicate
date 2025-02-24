import 'package:aina_flutter/core/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/core/widgets/restart_widget.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/widgets/avatar_edit_widget.dart';

// Добавляем провайдер для кэш-ключа
final profileCacheKeyProvider = StateProvider<int>((ref) => 0);

class CoworkingEditDataPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingEditDataPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingEditDataPage> createState() =>
      _CoworkingEditDataPageState();
}

class _CoworkingEditDataPageState extends ConsumerState<CoworkingEditDataPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController patronymicController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController iinController = TextEditingController();
  String selectedGender = 'NONE';
  bool _isDirty = false;
  bool _isLoading = false;
  File? _temporaryAvatar;

  // Validation state
  bool isFirstNameValid = true;
  bool isLastNameValid = true;
  bool isEmailValid = true;
  bool isIINValid = true;

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() async {
    try {
      final userData = await ref
          .read(promenadeProfileProvider)
          .getProfile(forceRefresh: true);

      if (mounted) {
        firstNameController.text = userData['firstname'] ?? '';
        lastNameController.text = userData['lastname'] ?? '';
        patronymicController.text = userData['patronymic'] ?? '';
        emailController.text = userData['email'] ?? '';
        iinController.text = userData['iin'] ?? '';
        selectedGender = userData['gender'] ?? 'NONE';

        // Update user data in auth state
        ref.read(authProvider.notifier).updateUserData(userData);

        // Update cache key to refresh the UI
        ref.read(profileCacheKeyProvider.notifier).state =
            DateTime.now().millisecondsSinceEpoch;
      }
    } catch (e) {
      // Handle error
    }
  }

  bool validateFields() {
    setState(() {
      isFirstNameValid = firstNameController.text.trim().isNotEmpty;
      isLastNameValid = lastNameController.text.trim().isNotEmpty;
    });

    return isFirstNameValid && isLastNameValid;
  }

  Future<bool> _onWillPop() async {
    if (_isDirty) {
      if (!validateFields()) {
        // Show warning modal about validation errors
        bool shouldExit = false;
        await BaseModal.show(
          context,
          title: 'modals.validation_error.title'.tr(),
          message: 'modals.validation_error.message'.tr(),
          buttons: [
            ModalButton(
              label: 'modals.validation_error.stay'.tr(),
              type: ButtonType.filled,
              onPressed: () {},
            ),
            ModalButton(
              label: 'modals.validation_error.discard'.tr(),
              type: ButtonType.bordered,
              textColor: Colors.red,
              onPressed: () {
                shouldExit = true;
              },
            ),
          ],
        );

        return shouldExit; // Only exit if user explicitly chose to discard
      }

      // If validation passes, show save changes modal
      bool? result;
      await BaseModal.show(
        context,
        title: 'modals.save_changes.title'.tr(),
        message: 'modals.save_changes.message'.tr(),
        buttons: [
          ModalButton(
            label: 'common.discard'.tr(),
            type: ButtonType.light,
            onPressed: () {
              result = false;
            },
          ),
          ModalButton(
            label: 'common.save'.tr(),
            type: ButtonType.filled,
            onPressed: () async {
              result = true;
            },
          ),
        ],
      );

      if (result == null) return false;
      if (result == true) {
        return await _saveChanges();
      }
      return true;
    }
    return true;
  }

  Future<bool> _saveChanges() async {
    if (!_isDirty) return true;

    if (!validateFields()) {
      return false;
    }

    try {
      final userData = await ref.read(promenadeProfileProvider).updateProfile(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            patronymic: patronymicController.text.trim(),
            email: emailController.text.trim(),
            gender: selectedGender,
            iin: iinController.text.trim(),
          );

      // Update user data in auth state
      ref.read(authProvider.notifier).updateUserData(userData);

      // Update cache key to refresh the UI
      ref.read(profileCacheKeyProvider.notifier).state =
          DateTime.now().millisecondsSinceEpoch;

      _isDirty = false;

      // Show success message after navigation
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.settings.edit.save_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }

      return true;
    } catch (e) {
      // Show error modal
      if (mounted) {
        await BaseModal.show(
          context,
          title: 'coworking.edit_data.error'.tr(),
          message: 'coworking.edit_data.update_error'.tr(),
          buttons: [
            ModalButton(
              label: 'common.ok'.tr(),
              type: ButtonType.filled,
              onPressed: () {},
            ),
          ],
        );
      }
      return false;
    }
  }

  void _markDirty() {
    setState(() {
      _isDirty = true;
    });
  }

  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', code);
    await prefs.setString('locale', code);
    await context.setLocale(Locale(code));
    await Future.delayed(const Duration(milliseconds: 50));

    if (context.mounted) {
      Navigator.of(context).pop();
      RestartWidget.restartApp(context);
    }
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'language'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('Қазақша', 'kk'),
            _buildLanguageOption('Русский', 'ru'),
            _buildLanguageOption('English', 'en'),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String code) {
    final isSelected = context.locale.languageCode == code;

    return InkWell(
      onTap: () => _changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.black : const Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    BaseModal.show(
      context,
      title: 'modals.logout.title'.tr(),
      message: 'modals.logout.message'.tr(),
      buttons: [
        ModalButton(
          label: 'common.cancel'.tr(),
          type: ButtonType.light,
          backgroundColor: AppColors.backgroundLight,
        ),
        ModalButton(
          label: 'common.logout'.tr(),
          type: ButtonType.normal,
          backgroundColor: AppColors.appBg,
          textColor: Colors.red,
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            context.go('/home');
          },
        ),
      ],
    );
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
    setState(() {
      _isLoading = true;
      _temporaryAvatar = null;
    });

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
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    patronymicController.dispose();
    emailController.dispose();
    iinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheKey = ref.watch(profileCacheKeyProvider);
    final profileAsync = ref.watch(promenadeProfileDataProvider(cacheKey));

    return profileAsync.when(
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => _buildErrorState(error),
      data: (profile) {
        final avatarUrl = profile['avatar']?['url'];

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            body: Container(
              color: AppColors.primary,
              child: SafeArea(
                child: Stack(
                  children: [
                    Container(
                      color: AppColors.white,
                      margin: const EdgeInsets.only(top: 64),
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          // Avatar section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarEditWidget(
                                avatarUrl: avatarUrl,
                                temporaryImage: _temporaryAvatar,
                                onAvatarPicked: _handleAvatarPicked,
                                onAvatarRemoved: _handleAvatarRemoved,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                '${'coworking.edit_data.phone'.tr()}: ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                profile['phone']['masked'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Form fields
                          CustomInputField(
                            controller: firstNameController,
                            placeholder: 'coworking.edit_data.firstname'.tr(),
                            isRequired: true,
                            hasError: !isFirstNameValid,
                            errorText: !isFirstNameValid
                                ? 'coworking.edit_data.required_field'.tr()
                                : null,
                            onChanged: (value) {
                              setState(() {
                                isFirstNameValid = value.trim().isNotEmpty;
                              });
                              _markDirty();
                            },
                          ),

                          CustomInputField(
                            controller: lastNameController,
                            placeholder: 'coworking.edit_data.lastname'.tr(),
                            isRequired: true,
                            hasError: !isLastNameValid,
                            errorText: !isLastNameValid
                                ? 'coworking.edit_data.required_field'.tr()
                                : null,
                            onChanged: (value) {
                              setState(() {
                                isLastNameValid = value.trim().isNotEmpty;
                              });
                              _markDirty();
                            },
                          ),

                          CustomInputField(
                            controller: patronymicController,
                            placeholder: 'coworking.edit_data.patronymic'.tr(),
                            onChanged: (_) => _markDirty(),
                          ),

                          CustomInputField(
                            controller: emailController,
                            placeholder: 'coworking.edit_data.email'.tr(),
                            isRequired: true,
                            hasError: !isEmailValid,
                            errorText: !isEmailValid
                                ? 'coworking.edit_data.invalid_email'.tr()
                                : null,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              setState(() {
                                isEmailValid = value.trim().contains('@');
                              });
                              _markDirty();
                            },
                          ),

                          CustomInputField(
                            controller: iinController,
                            placeholder: 'coworking.edit_data.iin'.tr(),
                            isRequired: true,
                            hasError: !isIINValid,
                            errorText: !isIINValid
                                ? 'coworking.edit_data.invalid_iin'.tr()
                                : null,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                isIINValid = value.trim().length == 12;
                              });
                              _markDirty();
                            },
                          ),
                          const SizedBox(height: 24),

                          // Gender selector
                          Text(
                            'profile.settings.edit.gender.title'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textDarkGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildGenderOption('FEMALE',
                                    'profile.settings.edit.gender.female'.tr()),
                              ),
                              Expanded(
                                child: _buildGenderOption('MALE',
                                    'profile.settings.edit.gender.male'.tr()),
                              ),
                              Expanded(
                                child: _buildGenderOption(
                                    'NONE',
                                    'profile.settings.edit.gender.not_specified'
                                        .tr()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Settings section
                          Text(
                            'coworking.edit_data.settings'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDarkGrey,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Language selector
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _showLanguageDialog,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'coworking.edit_data.language'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
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
                          const SizedBox(height: 32),

                          // Account section
                          Text(
                            'coworking.edit_data.account'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDarkGrey,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Logout button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _handleLogout,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Text(
                                      'coworking.edit_data.logout'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textDarkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomHeader(
                      title: 'coworking.edit_data.title'.tr(),
                      type: HeaderType.pop,
                      onBack: () async {
                        if (await _onWillPop()) {
                          if (context.mounted) {
                            context.pop();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
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
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Avatar skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[100]!,
                          highlightColor: Colors.grey[300]!,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Phone number skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form fields skeleton
                    ...List.generate(
                        5,
                        (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[100]!,
                                highlightColor: Colors.grey[300]!,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            )),

                    // Gender selector skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                                3,
                                (index) => Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Container(
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Settings section skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Account section skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CustomHeader(
                title: 'coworking.edit_data.title'.tr(),
                type: HeaderType.pop,
                onBack: () async {
                  if (await _onWillPop()) {
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = selectedGender == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
        _markDirty();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<String>(
              value: value,
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
                _markDirty();
              },
              activeColor: AppColors.secondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? AppColors.primary : AppColors.textDarkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Scaffold(
      body: Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
