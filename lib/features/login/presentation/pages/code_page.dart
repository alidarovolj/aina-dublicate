import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/services/storage_service.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:io' show Platform;

class CodeInputScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool isFromRegistration;

  const CodeInputScreen(
      {required this.phoneNumber, this.isFromRegistration = false, super.key});

  @override
  ConsumerState<CodeInputScreen> createState() => CodeInputScreenState();
}

class CodeInputScreenState extends ConsumerState<CodeInputScreen>
    with CodeAutoFill {
  final TextEditingController _codeController = TextEditingController();
  List<String> _codeDigits = ['', '', '', ''];
  bool isLoading = false;
  Timer? _timer;
  int _timeLeft = 59;
  bool _canResend = false;

  @override
  void codeUpdated() {
    if (code != null) {
      setState(() {
        _codeController.text = code!;
        _codeDigits = code!.split('');
      });
      checkCodeCompletion();
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromRegistration) {
        sendInitialLoginRequest();
      }
      _startTimer();
    });
  }

  @override
  void dispose() {
    cancel();
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 59;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    // Clear the input
    _codeController.clear();
    setState(() {
      _codeDigits = ['', '', '', ''];
    });

    await sendInitialLoginRequest();
    _startTimer();
  }

  Future<void> sendInitialLoginRequest() async {
    try {
      final response = await ref.read(requestCodeProvider).sendCodeRequest(
            '7${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}',
          );

      if (!mounted) return;

      if (response == null) {
        _showError('auth.server_no_response'.tr());
        return;
      }

      if (response.statusCode != 200) {
        _showError('auth.code_send_error_with_code'
            .tr(args: [response.statusCode.toString()]));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('auth.request_error'.tr());
    }
  }

  void checkCodeCompletion() async {
    if (isLoading) return;

    final code = _codeController.text;
    if (code.length == 4) {
      setState(() {
        isLoading = true;
      });

      try {
        final phoneFormatted =
            '7${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

        final response = await ref.read(requestCodeProvider).sendOTP(
              phoneFormatted,
              code,
            );

        if (!mounted) return;

        if (response == null) {
          _showError('auth.server_connection_error'.tr());
          return;
        }

        if (response.statusCode == 200 && response.data != null) {
          await _handleSuccessfulResponse(response.data);
        } else {
          throw Exception('auth.invalid_status_code'
              .tr(args: [response.statusCode.toString()]));
        }
      } catch (e) {
        if (!mounted) return;
        _showError('auth.error'.tr(args: [e.toString()]));
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleSuccessfulResponse(dynamic data) async {
    final responseData = Map<String, dynamic>.from(data);

    // Проверяем успешность ответа
    if (!responseData.containsKey('success') || !responseData['success']) {
      throw Exception('Неуспешный ответ от сервера');
    }

    // Получаем данные из вложенного объекта data
    final authData = Map<String, dynamic>.from(responseData['data']);

    if (!authData.containsKey('access_token')) {
      throw Exception('Токен отсутствует в ответе');
    }

    final token = authData['access_token'] as String;
    await StorageService.saveToken(token);

    final savedToken = await StorageService.getToken();
    if (savedToken != token) {
      throw Exception('Токен не был сохранен корректно');
    }

    await ref.read(authProvider.notifier).setToken(token);
    if (!mounted) return;

    // Get mallId from the current route or use a default value
    final mallId = GoRouterState.of(context).pathParameters['mallId'] ?? '2';
    context.go('/home');
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
                              'auth.enter_sms_code'.tr(),
                              style: GoogleFonts.lora(
                                fontSize: AppLength.xl,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'auth.sms_sent_to'.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '+7 ${widget.phoneNumber}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'auth.with_login_code'.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppLength.body),
                            AutofillGroup(
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(4, (index) {
                                      return Container(
                                        width: 58,
                                        height: 54,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            width: 1,
                                            color: AppColors.lightGrey,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _codeDigits[index],
                                            style: const TextStyle(
                                              fontSize: AppLength.lg,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textDarkGrey,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  Positioned.fill(
                                    child: TextField(
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode
                                      ],
                                      maxLength: 4,
                                      style: const TextStyle(
                                        color: Colors.transparent,
                                        fontSize: 1,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _codeDigits = value
                                              .padRight(4)
                                              .split('')
                                              .take(4)
                                              .toList();
                                        });
                                        if (value.length == 4) {
                                          checkCodeCompletion();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppLength.xxxl),
                            Center(
                              child: GestureDetector(
                                onTap: _resendCode,
                                child: Text(
                                  _canResend
                                      ? 'auth.resend_code'.tr()
                                      : 'auth.resend_code_timer'.tr(args: [
                                          _timeLeft < 10
                                              ? '0$_timeLeft'
                                              : _timeLeft.toString()
                                        ]),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CustomHeader(
                title: 'auth.confirmation'.tr(),
                type: HeaderType.close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
