import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:aina_flutter/app/providers/requests/auth/login_qr_provider.dart';
import 'package:aina_flutter/features/user/ui/widgets/simple_auth_warning_modal.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';

class AuthQrScanPage extends ConsumerStatefulWidget {
  const AuthQrScanPage({super.key});

  @override
  ConsumerState<AuthQrScanPage> createState() => _AuthQrScanPageState();
}

class _AuthQrScanPageState extends ConsumerState<AuthQrScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  Future<void> _handleQrCode(String? code) async {
    if (code == null || _isProcessing || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    if (!mounted) return;

    try {
      try {
        await controller?.pauseCamera();
      } catch (e) {
        // Ignore camera errors
      }

      // Проверка на авторизацию
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        // Показываем модальное окно с предупреждением
        await SimpleAuthWarningModal.show(context);

        return;
      }

      final service = ref.read(loginQrProvider);
      final response = await service.loginWithQr(
        code, // qr_token из сканированного QR кода
        authState.token ?? '', // Текущий токен пользователя
      );

      if (!mounted) return;

      // Безопасное получение данных из response
      Map<String, dynamic> data = {};
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      }

      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      if (data['success'] == true) {
        await BaseModal.show(
          context,
          title: 'auth_qr.success.title'.tr(),
          message:
              data['message']?.toString() ?? 'auth_qr.success.message'.tr(),
          buttons: [
            ModalButton(
              label: 'auth_qr.success.ok'.tr(),
              onPressed: () async {
                context.pop();
              },
              type: ButtonType.light,
            ),
          ],
        );
      } else {
        final String message =
            data['message']?.toString() ?? 'auth_qr.error.unknown'.tr();

        await BaseModal.show(
          context,
          message: message,
          buttons: [
            ModalButton(
              label: 'auth_qr.error.back'.tr(),
              onPressed: () async {
                context.pop();
              },
              type: ButtonType.light,
            ),
          ],
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'auth_qr.error.processing'.tr();

      if (e is DioException && e.response?.data != null) {
        try {
          final responseData = e.response!.data;
          // Handle different data types that might come from the API
          if (responseData is Map) {
            if (responseData['message'] != null) {
              errorMessage = responseData['message'].toString();
            } else if (responseData['error'] != null) {
              errorMessage = responseData['error'].toString();
            }
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        } catch (_) {
          // Игнорируем ошибки при обработке сообщения об ошибке
          debugPrint('Error parsing error response: $_');
        }
      }

      setState(() {
        _isProcessing = false;
      });

      await BaseModal.show(
        context,
        message: errorMessage,
        width: MediaQuery.of(context).size.width - 40,
        buttons: [
          ModalButton(
            label: 'auth_qr.error.back'.tr(),
            onPressed: () async {
              context.pop();
            },
            type: ButtonType.light,
          ),
        ],
      );
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
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
              CustomHeader(
                title: 'auth_qr.title'.tr(),
                type: HeaderType.pop,
                onBack: () {
                  try {
                    controller?.pauseCamera();
                    controller?.dispose();
                  } catch (e) {
                    debugPrint('Camera disposal error: $e');
                  }
                  if (mounted) {
                    context.pop();
                  }
                },
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  onPressed: () async {
                    try {
                      await controller?.flipCamera();
                    } catch (e) {
                      debugPrint('Camera flip error: $e');
                    }
                  },
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'auth_qr.processing'.tr(),
                          style: const TextStyle(
                            color: AppColors.secondary,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      _handleQrCode(scanData.code);
    });
  }

  @override
  void dispose() {
    try {
      controller?.pauseCamera();
      controller?.dispose();
    } catch (e) {
      debugPrint('Camera disposal error: $e');
    }
    super.dispose();
  }
}
