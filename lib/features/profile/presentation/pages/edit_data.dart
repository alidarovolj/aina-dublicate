import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart';

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

  @override
  void initState() {
    super.initState();
    final userData = UserProfile.fromJson(ref.read(authProvider).userData!);

    firstNameController = TextEditingController(text: userData.firstName);
    lastNameController = TextEditingController(text: userData.lastName);
    patronymicController =
        TextEditingController(text: userData.patronymic ?? '');
    emailController = TextEditingController(text: userData.email ?? '');
    licensePlateController =
        TextEditingController(text: userData.licensePlate ?? '');

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

    ref.read(selectedGenderProvider.notifier).state =
        getInitialGender(userData.gender);
  }

  void _onFocusChange() {
    final hasFocus = focusNodes.values.any((node) => node.hasFocus);
    if (!hasFocus) {
      _updateProfile();
    }
  }

  void _updateProfile() {
    ref.read(profileProvider).updateProfile(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          patronymic: patronymicController.text,
          email: emailController.text,
          licensePlate: licensePlateController.text,
          gender: getApiGender(ref.read(selectedGenderProvider)),
        );
  }

  void _onInputChange() {
    _updateProfile();
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
    final userAsync = ref.watch(authProvider);
    final userData = UserProfile.fromJson(userAsync.userData!);

    String selectedGender = ref.read(selectedGenderProvider);

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
                                    image: NetworkImage(userData.avatarUrl!),
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
                        const Text(
                          'Телефон: ',
                          style: TextStyle(
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
                    const Text(
                      'Основное',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDarkGrey,
                      ),
                    ),

                    CustomInputField(
                      controller: firstNameController,
                      placeholder: 'Имя*',
                      isRequired: true,
                      focusNode: focusNodes['firstName'],
                      onChanged: (value) {
                        _onInputChange();
                      },
                    ),

                    CustomInputField(
                      controller: lastNameController,
                      placeholder: 'Фамилия*',
                      isRequired: true,
                      focusNode: focusNodes['lastName'],
                      onChanged: (value) {
                        _onInputChange();
                      },
                    ),
                    CustomInputField(
                      controller: patronymicController,
                      placeholder: 'Отчество',
                      focusNode: focusNodes['patronymic'],
                      onChanged: (value) {
                        _onInputChange();
                      },
                    ),
                    CustomInputField(
                      controller: emailController,
                      placeholder: 'E-mail',
                      focusNode: focusNodes['email'],
                      onChanged: (value) {
                        _onInputChange();
                      },
                    ),

                    const SizedBox(height: 20),
                    CustomInputField(
                      controller: licensePlateController,
                      placeholder: 'Госномер авто (для оплаты паркинга)',
                      focusNode: focusNodes['licensePlate'],
                      onChanged: (value) {
                        _onInputChange();
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '*Изменить госномер можно не чаще 1 раза в сутки',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDarkGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender selection
                    const Text(
                      'Пол',
                      style: TextStyle(
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
                          child: _buildGenderOption('Жен.', selectedGender,
                              (value) {
                            ref.read(selectedGenderProvider.notifier).state =
                                value;
                          }),
                        ),
                        SizedBox(
                          width: 100,
                          child: _buildGenderOption('Муж.', selectedGender,
                              (value) {
                            ref.read(selectedGenderProvider.notifier).state =
                                value;
                          }),
                        ),
                        Expanded(
                          child: _buildGenderOption(
                              'Не указывать', selectedGender, (value) {
                            ref.read(selectedGenderProvider.notifier).state =
                                value;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Настройки',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDarkGrey,
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Language selection
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Выберите язык контента',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: const Text(
                          'Русский',
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          // Handle language selection
                        },
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
                        title: const Text(
                          'Выйти из аккаунта',
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          // Handle logout
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const CustomHeader(
                title: "Персональная информация",
                type: HeaderType.pop,
              ),
            ],
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
        _updateProfile();
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
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String getInitialGender(String? apiGender) {
    switch (apiGender?.toUpperCase()) {
      case 'FEMALE':
        return 'Жен.';
      case 'MALE':
        return 'Муж.';
      case 'NONE':
      default:
        return 'Не указывать';
    }
  }

  String getApiGender(String displayGender) {
    switch (displayGender) {
      case 'Жен.':
        return 'FEMALE';
      case 'Муж.':
        return 'MALE';
      case 'Не указывать':
      default:
        return 'NONE';
    }
  }
}
