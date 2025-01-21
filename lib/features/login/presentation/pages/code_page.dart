import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/services/storage_service.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodeInputScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool isFromRegistration;

  const CodeInputScreen(
      {required this.phoneNumber, this.isFromRegistration = false, super.key});

  @override
  ConsumerState<CodeInputScreen> createState() => CodeInputScreenState();
}

class CodeInputScreenState extends ConsumerState<CodeInputScreen> {
  final List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  bool isLoading = false;

  void checkCodeCompletion() async {
    if (isLoading) return; // Prevent multiple simultaneous requests

    final code = controllers.map((controller) => controller.text).join();
    if (code.length == 4) {
      setState(() {
        isLoading = true;
      });

      try {
        final phoneFormatted =
            '8${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

        final response = await ref.read(requestCodeProvider).sendOTP(
              phoneFormatted,
              code,
            );

        if (!mounted) return;

        if (response == null) {
          _showError('Ошибка соединения с сервером');
          return;
        }

        if (response.statusCode == 200 && response.data != null) {
          await _handleSuccessfulResponse(response.data);
        } else {
          throw Exception('Неверный статус код: ${response.statusCode}');
        }
      } catch (e) {
        if (!mounted) return;
        _showError('Ошибка авторизации: $e');
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
    if (!responseData.containsKey('access_token')) {
      throw Exception('Токен отсутствует в ответе');
    }

    final token = responseData['access_token'] as String;
    await StorageService.saveToken(token);

    final savedToken = await StorageService.getToken();
    if (savedToken != token) {
      throw Exception('Токен не был сохранен корректно');
    }

    await ref.read(authProvider.notifier).login(token);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    // Send initial login request
    Future<void> sendInitialLoginRequest() async {
      if (!widget.isFromRegistration) return; // Skip if not from registration

      try {
        final response = await ref.read(requestCodeProvider).sendCodeRequest(
              '8${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}',
            );

        if (response == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет ответа от сервера'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при отправке кода: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Ошибка при выполнении запроса: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Произошла ошибка при выполнении запроса'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Call the function when the page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendInitialLoginRequest();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppLength.body),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Введите код',
                  style: TextStyle(
                      fontSize: AppLength.xxxl, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppLength.tiny),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Мы отправили код на номер ',
                        style: TextStyle(
                            fontSize: AppLength.body,
                            color: Color.fromARGB(255, 99, 106, 107))),
                    TextSpan(
                        text: '+7 ${widget.phoneNumber}',
                        style: const TextStyle(
                            fontSize: AppLength.sm,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: AppLength.body),
              Row(
                children: List.generate(4, (index) {
                  return Container(
                    width: 58,
                    height: 54,
                    margin: const EdgeInsets.only(right: AppLength.xs),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppLength.body, horizontal: AppLength.xs),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      autofillHints:
                          index == 0 ? const [AutofillHints.oneTimeCode] : null,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: AppLength.lg, fontWeight: FontWeight.bold),
                      onChanged: (value) {
                        if (index == 0 && value.length > 1) {
                          final fullCode = value;
                          for (var i = 0;
                              i < controllers.length && i < fullCode.length;
                              i++) {
                            controllers[i].text = fullCode[i];
                          }
                          FocusScope.of(context).unfocus();
                          checkCodeCompletion();
                        } else if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                        checkCodeCompletion();
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '•',
                        hintStyle: TextStyle(
                          fontSize: AppLength.lg,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).map((widget) => Flexible(child: widget)).toList(),
              ),
              const SizedBox(height: AppLength.xxxl),
              const Text('Отправить новый код 1:30',
                  style: TextStyle(
                      fontSize: AppLength.body,
                      color: Color.fromARGB(255, 99, 106, 107))),
              const SizedBox(height: AppLength.xxxl),
              GestureDetector(
                onTap: () {
                  // Handle registration
                },
                child: const Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: TextStyle(
                      fontSize: AppLength.body,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
