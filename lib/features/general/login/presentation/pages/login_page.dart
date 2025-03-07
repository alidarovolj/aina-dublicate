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
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';

class PhoneNumberInputScreen extends ConsumerStatefulWidget {
  final String? buildingId;
  final String? buildingType;

  const PhoneNumberInputScreen({
    super.key,
    this.buildingId,
    this.buildingType,
  });

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
            SmsAutoFill().listenForCode;
          } catch (e) {
            print('Error starting SMS listener: $e');
          }
        }

        if (mounted) {
          final currentRoute = GoRouterState.of(context).uri.toString();
          String? buildingId;
          String? buildingType;

          // Extract building info from current route
          final routeParts = currentRoute.split('/');
          if (routeParts.length >= 3) {
            if (routeParts[1] == 'coworking') {
              buildingType = 'coworking';
              buildingId = routeParts[2];
            } else if (routeParts[1] == 'malls') {
              buildingType = 'mall';
              buildingId = routeParts[2];
            }
          }

          context.go('/code', extra: {
            'phoneNumber': _phoneController.text,
            'buildingId': widget.buildingId,
            'buildingType': widget.buildingType,
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'auth.code_send_error'.tr();

          if (e is DioException && e.response?.data != null) {
            final responseData = e.response?.data;
            if (responseData is Map<String, dynamic>) {
              errorMessage = responseData['message'] ?? errorMessage;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_not_available'.tr()),
          ),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(urlString);
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_error'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.url_error'.tr()),
          ),
        );
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
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(AppLength.four)),
                                    border: Border.all(
                                      width: 1,
                                      color: AppColors.darkGrey,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+7',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius:
                                          BorderRadius.circular(AppLength.four),
                                      border: Border.all(
                                        width: 1,
                                        color: AppColors.darkGrey,
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
                                          vertical: 14,
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
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final settingsAsync =
                                      ref.watch(settingsProvider);

                                  return settingsAsync.when(
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                    error: (error, stack) =>
                                        Text('about.settings_error'.tr()),
                                    data: (settings) => RichText(
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
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                _launchURL(settings
                                                    .userAgreementFile?.url);
                                              },
                                          ),
                                          TextSpan(
                                            text: 'auth.terms_and'.tr(),
                                          ),
                                          TextSpan(
                                            text: 'auth.privacy_policy'.tr(),
                                            style: const TextStyle(
                                              color: AppColors.textLinkColor,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                _launchURL(settings
                                                    .confidentialityAgreementFile
                                                    ?.url);
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
