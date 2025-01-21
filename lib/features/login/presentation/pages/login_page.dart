import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';

class PhoneNumberInputScreen extends ConsumerStatefulWidget {
  const PhoneNumberInputScreen({super.key});

  @override
  ConsumerState<PhoneNumberInputScreen> createState() =>
      _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState
    extends ConsumerState<PhoneNumberInputScreen> {
  final MaskedTextController _phoneController =
      MaskedTextController(mask: '(000) 000-00-00');

  bool isButtonEnabled = false;
  bool isLoading = false;

  void updateButtonState() {
    final phoneRegex =
        RegExp(r'^\(\d{3}\) \d{3}-\d{2}-\d{2}$'); // Регулярное выражение
    setState(() {
      isButtonEnabled = phoneRegex.hasMatch(_phoneController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppLength.body),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Вход в аккаунт',
                    style: TextStyle(
                      fontSize: AppLength.xxxl,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите ваш номер телефона. Мы отправим сообщение с 4 значным кодом ',
                    style: TextStyle(
                      fontSize: AppLength.body,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppLength.body),
                  Container(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLength.xs,
                            vertical: AppLength.body,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Text(
                            '+7',
                            style: TextStyle(
                              fontSize: AppLength.lg,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(AppLength.xs),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Номер телефона',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppLength.body,
                                  horizontal: AppLength.xs,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: AppLength.lg,
                                color: AppColors.textPrimary,
                              ),
                              onChanged: (value) {
                                updateButtonState();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppLength.xxxl),
                  const Text(
                    'Нет аккаунта? Зарегистрироваться',
                    style: TextStyle(
                      fontSize: AppLength.body,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLength.body),
              child: CustomButton(
                label: 'Отправить код',
                isEnabled: isButtonEnabled,
                isLoading: isLoading,
                onPressed: () async {
                  if (isButtonEnabled) {
                    setState(() {
                      isLoading = true;
                    });
                    final response =
                        await ref.read(requestCodeProvider).sendCodeRequest(
                              '8${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}',
                            );
                    setState(() {
                      isLoading = false;
                    });

                    if (response != null && response.statusCode == 200) {
                      context.push('/code', extra: _phoneController.text);
                    } else {
                      if (response != null && response.statusCode == 401) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ошибка при отправке кода'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пожалуйста, зарегистрируйтесь'),
                          ),
                        );
                        Future.delayed(const Duration(milliseconds: 200), () {
                          context.push('/info', extra: _phoneController.text);
                        });
                      }
                    }
                  }
                },
                type: ButtonType.normal,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
