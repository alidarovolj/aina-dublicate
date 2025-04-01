import 'package:aina_flutter/shared/ui/blocks/upper_header.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:aina_flutter/shared/ui/blocks/restart_widget.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';

class CodeInputScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? buildingId;
  final String? buildingType;
  final bool isFromRegistration;

  const CodeInputScreen({
    required this.phoneNumber,
    this.buildingId,
    this.buildingType,
    this.isFromRegistration = false,
    super.key,
  });

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
          // Извлекаем токен из ответа
          final responseData = response.data as Map<String, dynamic>;
          if (responseData.containsKey('success') &&
              responseData['success'] == true) {
            final authData = responseData['data'] as Map<String, dynamic>;
            if (authData.containsKey('access_token')) {
              final token = authData['access_token'] as String;
              await _handleSuccessfulLogin(token);
            } else {
              throw Exception('Токен отсутствует в ответе');
            }
          } else {
            throw Exception('Неуспешный ответ от сервера');
          }
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
    BaseSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
    );
  }

  Future<void> _handleSuccessfulLogin(String token) async {
    try {
      // Сохраняем токен в локальном хранилище
      await StorageService.saveToken(token);

      // Проверяем, что токен сохранился
      final savedToken = await StorageService.getToken();
      if (savedToken != token) {
        throw Exception('Токен не был сохранен корректно');
      }

      // Устанавливаем токен напрямую в ApiClient
      ApiClient().token = token;

      // Устанавливаем токен в провайдере авторизации
      await ref.read(authProvider.notifier).setToken(token);

      // Получаем данные пользователя и сохраняем их локально
      try {
        final response = await ApiClient().dio.get('/api/promenade/profile');

        if (response.data['success'] == true && response.data['data'] != null) {
          // Сохраняем данные пользователя в локальном хранилище
          await StorageService.saveUserData(response.data['data']);

          // Обновляем данные пользователя в провайдере
          ref.read(authProvider.notifier).updateUserData(response.data['data']);

          // Get user data for Amplitude event
          final userData = response.data['data'] as Map<String, dynamic>;
          final userId = userData['id'] ?? 0;
          final deviceId = userData['device_id'] ?? 0;

          // Determine platform
          String platform = 'web';
          if (Platform.isIOS) {
            platform = 'ios';
          } else if (Platform.isAndroid) {
            platform = 'android';
          }

          // Track main_click event after successful login
          await AmplitudeService().logEvent(
            'main_click',
            eventProperties: {
              'user_id': userId,
              'device_id': deviceId,
              'source': 'main',
              'Platform': platform,
            },
          );
        }
      } catch (e) {
        debugPrint('❌ Error getting user data: $e');
        // Продолжаем выполнение, даже если не удалось получить данные пользователя
      }

      // Добавляем задержку, чтобы состояние авторизации успело обновиться
      await Future.delayed(const Duration(milliseconds: 500));

      // Проверяем, что состояние авторизации обновилось
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        // Если состояние не обновилось, пробуем еще раз
        await ref.read(authProvider.notifier).setToken(token);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      // Если не удалось установить токен через провайдер, перезагружаем приложение
      if (mounted) {
        RestartWidget.restartApp(context);
        return;
      }
    }
    if (!mounted) return;

    // Добавляем еще одну проверку состояния авторизации перед навигацией
    final finalAuthState = ref.read(authProvider);

    // Добавляем дополнительную задержку перед навигацией
    await Future.delayed(const Duration(milliseconds: 300));

    if (widget.buildingType == 'coworking' && widget.buildingId != null) {
      context.go('/coworking/${widget.buildingId}/profile');
    } else if (widget.buildingType == 'mall' && widget.buildingId != null) {
      context.go('/malls/${widget.buildingId}/profile');
    } else {
      final currentRoute = GoRouterState.of(context).uri.toString();
      final routeParts = currentRoute.split('/');

      if (routeParts.length >= 3) {
        if (routeParts[1] == 'coworking') {
          context.go('/coworking/${routeParts[2]}/profile');
          return;
        } else if (routeParts[1] == 'malls') {
          context.go('/malls/${routeParts[2]}/profile');
          return;
        }
      }
      context.go('/home');
    }
  }

  Future<void> _verifyCode() async {
    if (_codeDigits.join('').length != 4) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final phoneFormatted =
          '7${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

      final requestService = ref.read(requestCodeProvider);
      final response = await requestService.sendOTP(
        phoneFormatted,
        _codeDigits.join(''),
      );

      if (!mounted) return;

      if (response == null) {
        throw Exception('auth.server_no_response'.tr());
      }

      if (response.statusCode == 200 && response.data != null) {
        // Извлекаем токен из ответа
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('success') &&
            responseData['success'] == true) {
          final authData = responseData['data'] as Map<String, dynamic>;
          if (authData.containsKey('access_token')) {
            final token = authData['access_token'] as String;
            await _handleSuccessfulLogin(token);
          } else {
            throw Exception('Токен отсутствует в ответе');
          }
        } else {
          throw Exception('Неуспешный ответ от сервера');
        }
      } else {
        throw Exception('auth.invalid_status_code'
            .tr(args: [response.statusCode.toString()]));
      }
    } catch (e) {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: e.toString(),
          type: SnackBarType.error,
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
                                      fontSize: 16,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '+7 ${widget.phoneNumber}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDarkGrey,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'auth.with_login_code'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
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
                                            color: AppColors.darkGrey,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(_codeDigits[index],
                                              style: GoogleFonts.lora(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textDarkGrey,
                                              )),
                                        ),
                                      );
                                    }),
                                  ),
                                  if (isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.white.withOpacity(0.8),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      AppColors.primary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned.fill(
                                    child: TextField(
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode
                                      ],
                                      maxLength: 4,
                                      showCursor: false,
                                      cursorWidth: 0,
                                      style: const TextStyle(
                                        color: Colors.transparent,
                                        height: 0,
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
                            const SizedBox(height: 36),
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
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
