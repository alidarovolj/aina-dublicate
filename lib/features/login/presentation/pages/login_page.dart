import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

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
    final phoneRegex = RegExp(r'^\(\d{3}\) \d{3}-\d{2}-\d{2}$');
    setState(() {
      isButtonEnabled = phoneRegex.hasMatch(_phoneController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: UpperHeader(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 96,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppLength.body),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Введите номер телефона',
                              style: GoogleFonts.lora(
                                fontSize: AppLength.xl,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Мы отправим вам SMS с 4-х значным кодом',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(height: AppLength.body),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12)),
                                    border: Border.all(
                                      width: 1,
                                      color: AppColors.lightGrey,
                                    ),
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
                                      color: AppColors.white,
                                      borderRadius:
                                          BorderRadius.circular(AppLength.xs),
                                      border: Border.all(
                                        width: 1,
                                        color: AppColors.lightGrey,
                                      ),
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
                                          horizontal: 14,
                                          vertical: 4,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: AppLength.sm,
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
                            const SizedBox(height: AppLength.xxxl),
                            CustomButton(
                              label: 'Получить код',
                              isEnabled: isButtonEnabled,
                              isLoading: isLoading,
                              onPressed: () async {
                                if (isButtonEnabled) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    await ref
                                        .read(requestCodeProvider)
                                        .sendCodeRequest(
                                          '7${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}',
                                        );

                                    if (mounted) {
                                      context.push('/code',
                                          extra: _phoneController.text);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Ошибка при отправке кода'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                              type: ButtonType.normal,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: AppLength.xxxl),
                            Center(
                              child: RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: AppLength.sm,
                                    color: AppColors.textDarkGrey,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Нажимая на кнопку, вы принимаете условия ',
                                    ),
                                    TextSpan(
                                      text: 'пользовательского соглашения',
                                      style: const TextStyle(
                                        color: AppColors.textLinkColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Add navigation to terms of service
                                          context.push('/terms');
                                        },
                                    ),
                                    const TextSpan(
                                      text: ' и ',
                                    ),
                                    TextSpan(
                                      text: 'политику конфиденциальности',
                                      style: const TextStyle(
                                        color: AppColors.textLinkColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Add navigation to privacy policy
                                          context.push('/privacy');
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppLength.body),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const CustomHeader(
                title: 'Авторизация',
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
