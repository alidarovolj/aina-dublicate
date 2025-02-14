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
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

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
  String? _appSignature;

  @override
  void initState() {
    super.initState();
    _getAppSignature();
  }

  Future<void> _getAppSignature() async {
    if (!Platform.isAndroid) return;

    try {
      final signature = await SmsAutoFill().getAppSignature;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app-hash', signature);
      setState(() {
        _appSignature = signature;
      });
      print('App Signature: $signature');
    } catch (e) {
      print('Error getting app signature: $e');
    }
  }

  void updateButtonState() {
    final phoneRegex = RegExp(r'^\(\d{3}\) \d{3}-\d{2}-\d{2}$');
    setState(() {
      isButtonEnabled = phoneRegex.hasMatch(_phoneController.text);
    });
  }

  void _onSubmit(BuildContext context) async {
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.length == 10) {
      setState(() {
        isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final appHash = prefs.getString('app-hash');

        await ref.read(requestCodeProvider).sendCodeRequest(
              '7$phoneNumber',
              appHash: appHash,
            );

        if (Platform.isAndroid) {
          try {
            await SmsAutoFill().listenForCode;
          } catch (e) {
            print('Error starting SMS listener: $e');
          }
        }

        if (mounted) {
          context.go('/code', extra: _phoneController.text);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при отправке кода'),
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
                              'auth.enter_phone'.tr(),
                              style: GoogleFonts.lora(
                                fontSize: AppLength.xl,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'auth.sms_code_info'.tr(),
                              style: const TextStyle(
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
                                      decoration: InputDecoration(
                                        hintText: 'auth.phone_number'.tr(),
                                        hintStyle: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                              label: 'auth.get_code'.tr(),
                              isEnabled: isButtonEnabled,
                              isLoading: isLoading,
                              onPressed: () async {
                                if (isButtonEnabled) {
                                  _onSubmit(context);
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
                                    TextSpan(
                                      text: 'auth.terms_prefix'.tr(),
                                    ),
                                    TextSpan(
                                      text: 'auth.terms_of_service'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.textLinkColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final url = Uri.parse(
                                              'https://aina-fashion-products-photos.object.pscloud.io/files/docs/Lic.pdf');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
                                        },
                                    ),
                                    TextSpan(
                                      text: 'auth.terms_and'.tr(),
                                    ),
                                    TextSpan(
                                      text: 'auth.privacy_policy'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.textLinkColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final url = Uri.parse(
                                              'https://aina-fashion-products-photos.object.pscloud.io/files/docs/policy.pdf');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
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
              CustomHeader(
                title: 'auth.title'.tr(),
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
