import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/providers/requests/promotions/register_receipt.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/providers/requests/promotions/details.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

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

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  Future<void> _handleQrCode(String? code) async {
    if (code == null || _isProcessing || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    if (!mounted) return;

    try {
      await controller?.pauseCamera();

      final promotionDetailsService = ref.read(requestPromotionDetailsProvider);
      final promotionResponse = await promotionDetailsService
          .promotionDetails(widget.promotionId.toString());

      if (promotionResponse == null || !promotionResponse.data['success']) {
        throw Exception('Failed to fetch promotion details');
      }

      final promotionData =
          promotionResponse.data['data'] as Map<String, dynamic>;
      final building = promotionData['building'] as Map<String, dynamic>?;
      final buildingId = building?['id']?.toString() ?? widget.mallId;

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
          message: 'qr.success.message'.tr(args: [tickets.join(", ")]),
          buttons: [
            ModalButton(
              label: 'qr.success.to_profile'.tr(),
              onPressed: () async {
                context.go('/malls/${widget.mallId}/profile');
              },
              textColor: AppColors.secondary,
              backgroundColor: Colors.white,
            ),
            ModalButton(
              label: 'qr.success.back_to_promotion'.tr(),
              onPressed: () async {
                context.go(
                    '/malls/${widget.mallId}/promotions/${widget.promotionId}');
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
              ),
              CustomHeader(
                title: 'qr.title'.tr(),
                type: HeaderType.pop,
                onBack: () {
                  controller?.pauseCamera();
                  controller?.dispose();
                  if (mounted) {
                    context.pop();
                  }
                },
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'lib/core/assets/images/qr.svg',
                      width: 200,
                      height: 200,
                    ),
                  ],
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
    controller?.pauseCamera();
    controller?.dispose();
    super.dispose();
  }
}
