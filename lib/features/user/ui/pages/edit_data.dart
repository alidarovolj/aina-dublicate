import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/ui/blocks/restart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart';
import 'package:aina_flutter/shared/ui/blocks/avatar_edit_widget.dart';
import 'package:aina_flutter/shared/ui/widgets/base_radio.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';

final selectedGenderProvider = StateProvider<String>((ref) => 'Не указывать');

class EditDataPage extends ConsumerStatefulWidget {
  final int mallId;

  const EditDataPage({
    super.key,
    required this.mallId,
  });

  @override
  ConsumerState<EditDataPage> createState() => _EditDataPageState();
}

class _EditDataPageState extends ConsumerState<EditDataPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController patronymicController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController iinController = TextEditingController();
  final Map<String, FocusNode> focusNodes = {
    'firstName': FocusNode(),
    'lastName': FocusNode(),
    'patronymic': FocusNode(),
    'email': FocusNode(),
    'licensePlate': FocusNode(),
    'iin': FocusNode(),
  };
  bool _isLoading = false;
  bool _hasChanges = false;
  bool isEmailValid = true;
  bool isIINValid = true;

  @override
  void initState() {
    super.initState();
    for (var node in focusNodes.values) {
      node.addListener(_onFieldChanged);
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await ref.read(userProvider.future);
    if (!mounted) return;

    debugPrint('Loading user data: ${userData.toString()}');

    // Отключим слушателей перед заполнением полей
    firstNameController.removeListener(_onFieldChanged);
    lastNameController.removeListener(_onFieldChanged);
    patronymicController.removeListener(_onFieldChanged);
    emailController.removeListener(_onFieldChanged);
    licensePlateController.removeListener(_onFieldChanged);
    iinController.removeListener(_onFieldChanged);

    // Заполняем поля
    firstNameController.text = userData.firstName ?? '';
    lastNameController.text = userData.lastName ?? '';
    patronymicController.text = userData.patronymic ?? '';
    emailController.text = userData.email ?? '';
    licensePlateController.text = userData.licensePlate ?? '';

    // Поскольку в классе UserProfile нет поля iin, получим его из API Promenade
    await _loadAdditionalUserData();

    // Convert API gender value to translation key
    final gender = switch (userData.gender?.toUpperCase()) {
      'MALE' => 'profile.settings.edit.gender.male'.tr(),
      'FEMALE' => 'profile.settings.edit.gender.female'.tr(),
      _ => 'profile.settings.edit.gender.not_specified'.tr(),
    };

    ref.read(selectedGenderProvider.notifier).state = gender;

    // Add listeners to track changes после заполнения всех полей
    firstNameController.addListener(_onFieldChanged);
    lastNameController.addListener(_onFieldChanged);
    patronymicController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    licensePlateController.addListener(_onFieldChanged);
    iinController.addListener(_onFieldChanged);

    // Сбрасываем флаг изменений после загрузки всех данных
    if (mounted) {
      setState(() {
        _hasChanges = false;
      });
    }
  }

  Future<void> _loadAdditionalUserData() async {
    try {
      // Получаем данные профиля напрямую через API Promenade
      final profileService = ref.read(promenadeProfileProvider);
      final userData = await profileService.getProfile(forceRefresh: true);

      debugPrint('Loaded additional profile data: $userData');

      if (userData.containsKey('iin')) {
        // Отключаем слушателя на время заполнения поля, чтобы не установить флаг _hasChanges
        iinController.removeListener(_onFieldChanged);
        iinController.text = userData['iin'] ?? '';
        // Возвращаем слушателя обратно
        iinController.addListener(_onFieldChanged);
        debugPrint('Loaded IIN from additional API: ${userData['iin']}');
      } else {
        debugPrint('IIN not found in additional user data');
        // Отключаем слушателя на время заполнения поля
        iinController.removeListener(_onFieldChanged);
        iinController.text = '';
        // Возвращаем слушателя обратно
        iinController.addListener(_onFieldChanged);
      }
    } catch (e) {
      debugPrint('Error loading additional user data: $e');
      // Отключаем слушателя на время заполнения поля
      iinController.removeListener(_onFieldChanged);
      iinController.text = '';
      // Возвращаем слушателя обратно
      iinController.addListener(_onFieldChanged);
    }

    // Сбрасываем флаг изменений после загрузки данных
    if (mounted) {
      setState(() {
        _hasChanges = false;
      });
    }
  }

  void _onFieldChanged() {
    if (!mounted) return;
    _hasChanges = true;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isLoading = true);

      final file = File(image.path);
      await ref.read(promenadeProfileProvider).uploadAvatar(file);

      if (!mounted) return;

      // Обновляем данные профиля
      ref.invalidate(userProvider);
      ref.invalidate(userTicketsProvider);

      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_updated'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_error'.tr(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      setState(() => _isLoading = true);

      await ref.read(promenadeProfileProvider).removeAvatar();

      // Обновляем данные профиля
      ref.invalidate(userProvider);
      ref.invalidate(userTicketsProvider);

      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_removed'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.avatar_error'.tr(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateFields()) return;

    try {
      setState(() => _isLoading = true);

      // Convert translation key back to API gender value
      final gender = switch (ref.read(selectedGenderProvider)) {
        var g when g == 'profile.settings.edit.gender.male'.tr() => 'MALE',
        var g when g == 'profile.settings.edit.gender.female'.tr() => 'FEMALE',
        _ => 'NONE',
      };

      final success = await ref.read(profileProvider).updateProfile(
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            patronymic: patronymicController.text,
            email: emailController.text,
            licensePlate: licensePlateController.text,
            gender: gender,
            iin: iinController.text,
          );

      if (!mounted) return;

      if (success) {
        // Обновляем данные профиля
        ref.invalidate(userProvider);
        ref.invalidate(userTicketsProvider);

        BaseSnackBar.show(
          context,
          message: 'profile.settings.edit.update_success'.tr(),
          type: SnackBarType.success,
        );

        setState(() => _hasChanges = false);
      } else {
        BaseSnackBar.show(
          context,
          message: 'profile.settings.edit.update_error'.tr(),
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'profile.settings.edit.update_error'.tr(),
        type: SnackBarType.error,
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
    licensePlateController.dispose();
    iinController.dispose();
    for (var node in focusNodes.values) {
      node.removeListener(_onFieldChanged);
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', code);
    await prefs.setString('locale', code);
    await context.setLocale(Locale(code));
    await Future.delayed(const Duration(milliseconds: 50));

    if (context.mounted) {
      context.pop();
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
                  onPressed: () => context.pop(),
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: userAsync.when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
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
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Avatar and phone section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarEditWidget(
                              avatarUrl: userData.avatarUrl,
                              isLoading: _isLoading,
                              onAvatarPicked: (file) async {
                                try {
                                  setState(() => _isLoading = true);
                                  await ref
                                      .read(promenadeProfileProvider)
                                      .uploadAvatar(file);

                                  if (!mounted) return;

                                  // Обновляем данные профиля
                                  ref.invalidate(userProvider);
                                  ref.invalidate(userTicketsProvider);

                                  BaseSnackBar.show(
                                    context,
                                    message:
                                        'profile.settings.edit.avatar_updated'
                                            .tr(),
                                    type: SnackBarType.success,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  BaseSnackBar.show(
                                    context,
                                    message:
                                        'profile.settings.edit.avatar_error'
                                            .tr(),
                                    type: SnackBarType.error,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              onAvatarRemoved: () async {
                                try {
                                  setState(() => _isLoading = true);

                                  await ref
                                      .read(promenadeProfileProvider)
                                      .removeAvatar();

                                  // Обновляем данные профиля
                                  ref.invalidate(userProvider);
                                  ref.invalidate(userTicketsProvider);

                                  if (!mounted) return;
                                  BaseSnackBar.show(
                                    context,
                                    message:
                                        'profile.settings.edit.avatar_removed'
                                            .tr(),
                                    type: SnackBarType.success,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  BaseSnackBar.show(
                                    context,
                                    message:
                                        'profile.settings.edit.avatar_error'
                                            .tr(),
                                    type: SnackBarType.error,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              '${'profile.settings.edit.phone'.tr()}: ',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              userData.maskedPhone,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'profile.settings.edit.main_info'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkGrey,
                          ),
                        ),

                        CustomInputField(
                          controller: firstNameController,
                          placeholder: 'profile.settings.edit.firstname'.tr(),
                          focusNode: focusNodes['firstName'],
                          onChanged: (_) => {_hasChanges = true},
                        ),

                        CustomInputField(
                          controller: lastNameController,
                          placeholder: 'profile.settings.edit.lastname'.tr(),
                          focusNode: focusNodes['lastName'],
                          onChanged: (_) => {_hasChanges = true},
                        ),
                        CustomInputField(
                          controller: patronymicController,
                          placeholder: 'profile.settings.edit.patronymic'.tr(),
                          focusNode: focusNodes['patronymic'],
                          onChanged: (_) => {_hasChanges = true},
                        ),
                        CustomInputField(
                          controller: emailController,
                          placeholder: 'profile.settings.edit.email'.tr(),
                          focusNode: focusNodes['email'],
                          onChanged: (_) => {_hasChanges = true},
                        ),

                        const SizedBox(height: 20),
                        CustomInputField(
                          controller: licensePlateController,
                          placeholder: 'profile.settings.edit.car_number'.tr(),
                          focusNode: focusNodes['licensePlate'],
                          onChanged: (_) => {_hasChanges = true},
                        ),
                        const SizedBox(height: 16),

                        CustomInputField(
                          controller: iinController,
                          placeholder: 'coworking.edit_data.iin'.tr(),
                          focusNode: focusNodes['iin'],
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          onChanged: (_) => {_hasChanges = true},
                        ),
                        const SizedBox(height: 16),

                        // Gender selection
                        BaseRadio(
                          title: 'profile.settings.edit.gender.title'.tr(),
                          selectedValue: ref.watch(selectedGenderProvider),
                          options: [
                            'profile.settings.edit.gender.female'.tr(),
                            'profile.settings.edit.gender.male'.tr(),
                            'profile.settings.edit.gender.not_specified'.tr(),
                          ],
                          onChanged: (value) {
                            ref.read(selectedGenderProvider.notifier).state =
                                value;
                            _hasChanges = true;
                          },
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'profile.settings.edit.settings'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkGrey,
                          ),
                        ),

                        const SizedBox(height: 8),

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
                    title: 'profile.settings.edit.title'.tr(),
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
      ),
    );
  }

  bool _validateFields() {
    return true;
  }

  void _markDirty() {
    if (!mounted) return;
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
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
              context.pop();
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
        await _saveChanges();
        return true;
      }
      return result == true;
    }
    return true;
  }

  Future<void> _handleLogout() async {
    final userData = await ref.read(userProvider.future);

    await BaseModal.show(
      context,
      title: 'profile.settings.edit.logout.title'.tr(),
      message: 'profile.settings.edit.logout.message'
          .tr(args: [userData.maskedPhone]),
      buttons: [
        ModalButton(
          label: 'profile.settings.edit.logout.cancel'.tr(),
          type: ButtonType.light,
          backgroundColor: AppColors.backgroundLight,
          onPressed: () => {},
        ),
        ModalButton(
          label: 'profile.settings.edit.logout.confirm'.tr(),
          type: ButtonType.normal,
          backgroundColor: AppColors.appBg,
          textColor: Colors.red,
          onPressed: () async {
            context.pop(); // Закрываем модальное окно

            // Clear API client token and force new instance first
            ApiClient().token = null;
            ApiClient().dispose(); // Force new instance on next use

            // Clear all storage and state
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear(); // Clear all stored data

            // Perform logout
            await ref.read(authProvider.notifier).logout();

            // Clear all providers
            ref.invalidate(userProvider);
            ref.invalidate(authProvider);
            ref.refresh(userProvider);
            ref.refresh(authProvider);

            if (!context.mounted) return;

            // Navigate to home with stack replacement
            context.go('/home');

            // Wait for navigation and state cleanup
            await Future.delayed(const Duration(milliseconds: 100));

            if (context.mounted) {
              RestartWidget.restartApp(context);
            }
          },
        ),
      ],
    );
  }
}
