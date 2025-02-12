import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/widgets/restart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/core/api/api_client.dart';

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
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController patronymicController;
  late TextEditingController emailController;
  late TextEditingController licensePlateController;
  late Map<String, FocusNode> focusNodes;
  bool _isDirty = false;

  // Validation state
  bool isFirstNameValid = true;
  bool isLastNameValid = true;
  bool isLicensePlateValid = true;

  @override
  void initState() {
    super.initState();

    // Initialize with empty values first
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    patronymicController = TextEditingController();
    emailController = TextEditingController();
    licensePlateController = TextEditingController();

    focusNodes = {
      'firstName': FocusNode(),
      'lastName': FocusNode(),
      'patronymic': FocusNode(),
      'email': FocusNode(),
      'licensePlate': FocusNode(),
    };

    for (var node in focusNodes.values) {
      node.addListener(_onFocusChange);
    }

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() async {
    try {
      final requestService = ref.read(requestCodeProvider);
      final response = await requestService.userProfile();

      if (response != null && response.statusCode == 200 && mounted) {
        final userData = UserProfile.fromJson(response.data);

        firstNameController.text = userData.firstName;
        lastNameController.text = userData.lastName;
        patronymicController.text = userData.patronymic ?? '';
        emailController.text = userData.email ?? '';
        licensePlateController.text = userData.licensePlate ?? '';

        ref.read(selectedGenderProvider.notifier).state =
            getInitialGender(userData.gender);

        // Invalidate the provider to refresh UI
        ref.invalidate(userProvider);
      }
    } catch (e) {
      // Handle error
    }
  }

  bool validateFields() {
    setState(() {
      isFirstNameValid = firstNameController.text.trim().isNotEmpty;
      isLastNameValid = lastNameController.text.trim().isNotEmpty;
      isLicensePlateValid = licensePlateController.text.trim().length >= 5;
    });

    return isFirstNameValid && isLastNameValid && isLicensePlateValid;
  }

  void _onFocusChange() {
    final hasFocus = focusNodes.values.any((node) => node.hasFocus);
    if (!hasFocus) {
      _markDirty();
    }
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
            type: ButtonType.bordered,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.settings.edit.validation_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final success = await _updateProfile();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.settings.edit.save_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
    return success;
  }

  void _markDirty() {
    setState(() {
      _isDirty = true;
    });
  }

  Future<bool> _updateProfile() async {
    if (!validateFields()) {
      return false;
    }

    try {
      final requestService = ref.read(requestCodeProvider);
      final response = await requestService.updateAinaProfile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        patronymic: patronymicController.text,
        email: emailController.text,
        licensePlate: licensePlateController.text,
        gender: getApiGender(ref.read(selectedGenderProvider)),
      );

      if (response != null && response.statusCode == 200 && mounted) {
        // Invalidate and refresh the userProvider to fetch new data
        ref.invalidate(userProvider);
        await ref.read(userProvider.future);
        setState(() {
          _isDirty = false;
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.settings.edit.update_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    patronymicController.dispose();
    emailController.dispose();
    licensePlateController.dispose();
    for (var node in focusNodes.values) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    super.dispose();
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: userData.avatarUrl != null
                                    ? null
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                                image: userData.avatarUrl != null
                                    ? DecorationImage(
                                        image:
                                            NetworkImage(userData.avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: userData.avatarUrl == null
                                  ? const Center(
                                      child: Icon(
                                        Icons.person_add,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )
                                  : null,
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
                          isRequired: true,
                          focusNode: focusNodes['firstName'],
                          hasError: !isFirstNameValid,
                          errorText: !isFirstNameValid
                              ? 'profile.settings.edit.required_field'.tr()
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
                          placeholder: 'profile.settings.edit.lastname'.tr(),
                          isRequired: true,
                          focusNode: focusNodes['lastName'],
                          hasError: !isLastNameValid,
                          errorText: !isLastNameValid
                              ? 'profile.settings.edit.required_field'.tr()
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
                          placeholder: 'profile.settings.edit.patronymic'.tr(),
                          focusNode: focusNodes['patronymic'],
                          onChanged: (_) => _markDirty(),
                        ),
                        CustomInputField(
                          controller: emailController,
                          placeholder: 'profile.settings.edit.email'.tr(),
                          focusNode: focusNodes['email'],
                          onChanged: (_) => _markDirty(),
                        ),

                        const SizedBox(height: 20),
                        CustomInputField(
                          controller: licensePlateController,
                          placeholder: 'profile.settings.edit.car_number'.tr(),
                          focusNode: focusNodes['licensePlate'],
                          isRequired: true,
                          hasError: !isLicensePlateValid,
                          errorText: !isLicensePlateValid
                              ? licensePlateController.text.trim().isEmpty
                                  ? 'profile.settings.edit.required_field'.tr()
                                  : 'profile.settings.edit.min_length'.tr()
                              : null,
                          onChanged: (value) {
                            setState(() {
                              isLicensePlateValid = value.trim().length >= 5;
                            });
                            _markDirty();
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'profile.settings.edit.car_number_note'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gender selection
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
                            SizedBox(
                              width: 100,
                              child: _buildGenderOption(
                                  'profile.settings.edit.gender.female'.tr(),
                                  ref.read(selectedGenderProvider), (value) {
                                ref
                                    .read(selectedGenderProvider.notifier)
                                    .state = value;
                                _markDirty();
                              }),
                            ),
                            SizedBox(
                              width: 100,
                              child: _buildGenderOption(
                                  'profile.settings.edit.gender.male'.tr(),
                                  ref.read(selectedGenderProvider), (value) {
                                ref
                                    .read(selectedGenderProvider.notifier)
                                    .state = value;
                                _markDirty();
                              }),
                            ),
                            Expanded(
                              child: _buildGenderOption(
                                  'profile.settings.edit.gender.not_specified'
                                      .tr(),
                                  ref.read(selectedGenderProvider), (value) {
                                ref
                                    .read(selectedGenderProvider.notifier)
                                    .state = value;
                                _markDirty();
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              'profile.settings.edit.logout.button'.tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () async {
                              final userAsync = ref.read(userProvider);

                              final phone = userAsync.when(
                                data: (userData) => userData.maskedPhone,
                                loading: () => '',
                                error: (_, __) => '',
                              );

                              // Show confirmation modal
                              await BaseModal.show(
                                context,
                                message:
                                    'profile.settings.edit.logout.confirmation'
                                        .tr()
                                        .replaceAll('{}', phone),
                                buttons: [
                                  ModalButton(
                                    label: 'profile.settings.edit.logout.cancel'
                                        .tr(),
                                    type: ButtonType.normal,
                                    textColor: AppColors.primary,
                                    backgroundColor: AppColors.lightGrey,
                                  ),
                                  ModalButton(
                                    label:
                                        'profile.settings.edit.logout.confirm'
                                            .tr(),
                                    type: ButtonType.normal,
                                    textColor: Colors.red,
                                    backgroundColor: Colors.white,
                                    onPressed: () async {
                                      print('Logout: Starting logout process');
                                      Navigator.of(context).pop();

                                      // Clear API client token and force new instance first
                                      print(
                                          'Logout: Clearing API client token');
                                      ApiClient().token = null;
                                      ApiClient()
                                          .dispose(); // Force new instance on next use

                                      // Clear all storage and state
                                      print(
                                          'Logout: Clearing SharedPreferences');
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs
                                          .clear(); // Clear all stored data

                                      // Perform logout
                                      print(
                                          'Logout: Calling auth provider logout');
                                      await ref
                                          .read(authProvider.notifier)
                                          .logout();

                                      // Clear all providers
                                      print(
                                          'Logout: Invalidating all providers');
                                      ref.invalidate(userProvider);
                                      ref.invalidate(authProvider);

                                      // Force dispose providers
                                      ref.refresh(userProvider);
                                      ref.refresh(authProvider);

                                      if (!context.mounted) return;

                                      // Navigate to home and wait for navigation to complete
                                      print('Logout: Navigating to home');
                                      context.go('/');

                                      // Wait for navigation and state cleanup
                                      print('Logout: Waiting before restart');
                                      await Future.delayed(
                                          const Duration(milliseconds: 1000));

                                      if (context.mounted) {
                                        print(
                                            'Logout: Attempting to restart app');

                                        // Force a complete rebuild of the widget tree
                                        RestartWidget.restartApp(context);

                                        // Additional cleanup after restart
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            // Create a new API client instance
                                            ApiClient().dispose();
                                            ApiClient().token = null;

                                            // Reinitialize providers with fresh state
                                            ref.invalidate(userProvider);
                                            ref.invalidate(authProvider);
                                            ref.refresh(userProvider);
                                            ref.refresh(authProvider);
                                          }
                                        });

                                        print('Logout: Process complete');
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
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
                          Navigator.of(context).pop();
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

  Widget _buildGenderOption(
      String value, String groupValue, Function(String) onChanged) {
    return InkWell(
      onTap: () {
        onChanged(value);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (value) => onChanged(value!),
              activeColor: AppColors.secondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: AppColors.textDarkGrey),
          ),
        ],
      ),
    );
  }

  String getInitialGender(String? apiGender) {
    switch (apiGender?.toUpperCase()) {
      case 'FEMALE':
        return 'profile.settings.edit.gender.female'.tr();
      case 'MALE':
        return 'profile.settings.edit.gender.male'.tr();
      case 'NONE':
      default:
        return 'profile.settings.edit.gender.not_specified'.tr();
    }
  }

  String getApiGender(String displayGender) {
    if (displayGender == 'profile.settings.edit.gender.female'.tr()) {
      return 'FEMALE';
    } else if (displayGender == 'profile.settings.edit.gender.male'.tr()) {
      return 'MALE';
    } else {
      return 'NONE';
    }
  }
}
