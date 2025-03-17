import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/providers/requests/promotions/register_receipt.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';

class PromotionQrPage extends ConsumerStatefulWidget {
  final int promotionId;
  final String mallId;

  const PromotionQrPage({
    super.key,
    required this.promotionId,
    required this.mallId,
  });

  @override
  ConsumerState<PromotionQrPage> createState() => _PromotionQrPageState();
}

class _PromotionQrPageState extends ConsumerState<PromotionQrPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _lastScannedCode;

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

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

    // Логируем событие сканирования
    AmplitudeService().logEvent(
      'scan_receipt',
      eventProperties: {
        'Platform': _getPlatform(),
      },
    );

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

      print('🔍 Debug QR Scanner:');
      print('   Initial mallId: ${widget.mallId}');

      if (widget.mallId.isEmpty) {
        print('❌ Error: mallId is empty');
        BaseSnackBar.show(
          context,
          message: 'errors.mall_id_not_found'.tr(),
          type: SnackBarType.error,
        );
        return;
      }

      final container = ProviderScope.containerOf(context);
      final buildingsAsync = container.read(buildingsProvider);

      final buildingsData = buildingsAsync.value;
      if (buildingsData == null) {
        print('❌ Error: buildingsData is null');
        BaseSnackBar.show(
          context,
          message: 'errors.buildings_data_unavailable'.tr(),
          type: SnackBarType.error,
        );
        return;
      }

      print('📦 Buildings data:');
      print('   Mall count: ${buildingsData['mall']?.length ?? 0}');
      print('   Coworking count: ${buildingsData['coworking']?.length ?? 0}');

      final buildings = [
        ...buildingsData['mall'] ?? [],
        ...buildingsData['coworking'] ?? []
      ];

      print('🏢 Total buildings: ${buildings.length}');

      final building = buildings.firstWhere(
        (b) => b.id.toString() == widget.mallId,
        orElse: () {
          print(
              '⚠️ Building not found with mallId: ${widget.mallId}, using first building');
          return buildings.first;
        },
      );

      print('🎯 Found building:');
      print('   ID: ${building.id}');
      print('   Type: ${building.type}');
      print('   Name: ${building.name}');

      final service = ref.read(registerReceiptProvider);
      final response = await service.registerReceipt(
        widget.promotionId.toString(),
        code,
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      if (data['tickets'] != null) {
        List<int> tickets = [];
        if (data['tickets'] is List) {
          final List<dynamic> ticketsList = data['tickets'] as List<dynamic>;
          tickets = ticketsList.map((e) => e as int).toList();
        } else if (data['tickets'] is int) {
          tickets = [data['tickets'] as int];
        }

        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        await BaseModal.show(
          context,
          title: 'qr.success.title'.tr(),
          message: 'qr.success.message'
              .tr(namedArgs: {'tickets': tickets.join(", ")}),
          buttons: [
            ModalButton(
              label: 'qr.success.to_tickets'.tr(),
              onPressed: () async {
                context.pushReplacement('/tickets/${widget.mallId}',
                    extra: {'isFromQr': true});
              },
              textColor: AppColors.secondary,
              backgroundColor: Colors.white,
            ),
            ModalButton(
              label: 'qr.success.back_to_promotion'.tr(),
              onPressed: () async {
                context.pop();
              },
              type: ButtonType.light,
            ),
          ],
        );
      } else {
        final String message =
            data['message'] as String? ?? 'qr.error.unknown'.tr();

        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        await BaseModal.show(
          context,
          message: message,
          buttons: [
            ModalButton(
              label: 'qr.error.back'.tr(),
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

      String errorMessage = 'qr.error.processing'.tr();

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
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
            label: 'qr.error.back'.tr(),
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
                title: 'qr.title'.tr(),
                type: HeaderType.pop,
                onBack: () {
                  try {
                    controller?.pauseCamera();
                    controller?.dispose();
                  } catch (e) {
                    print('Camera disposal error: $e');
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
                      print('Camera flip error: $e');
                    }
                  },
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                  ),
                ),
              ),
              // Center(
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       SvgPicture.asset(
              //         'lib/core/assets/images/qr.svg',
              //         width: 200,
              //         height: 200,
              //       ),
              //     ],
              //   ),
              // ),
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
                          'qr.processing'.tr(),
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
      print('Camera disposal error: $e');
    }
    super.dispose();
  }
}
