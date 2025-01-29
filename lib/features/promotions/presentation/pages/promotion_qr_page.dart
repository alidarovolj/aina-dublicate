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

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  Future<void> _handleQrCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    if (!mounted) return;

    try {
      // First get the promotion details to get the building info
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

      // Now register the receipt
      final service = ref.read(registerReceiptProvider);
      final response = await service.registerReceipt(
        widget.promotionId.toString(),
        code,
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      if (data['tickets'] != null) {
        final List<dynamic> ticketsList = data['tickets'] as List<dynamic>;
        final List<int> tickets = ticketsList.map((e) => e as int).toList();
        final double amount = (data['amount'] as num).toDouble();

        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        controller?.pauseCamera();
        await BaseModal.show(
          context,
          title: 'Ваш чек зарегистрирован. Поздравляем!',
          message:
              'Номера купонов для участия в розыгрыше: ${tickets.join(", ")}\nНомер хранится в профиле, в разделе «Купоны».',
          buttons: [
            ModalButton(
              label: 'В профиль',
              onPressed: () async {
                context.go('/malls/${widget.mallId}/profile');
              },
              textColor: AppColors.secondary,
              backgroundColor: Colors.white,
            ),
            ModalButton(
              label: 'Назад к акции',
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
            data['message'] as String? ?? 'Неизвестная ошибка';

        setState(() {
          _isProcessing = false;
        });

        if (!mounted) return;

        controller?.pauseCamera();
        await BaseModal.show(
          context,
          message: message,
          buttons: [
            ModalButton(
              label: 'Сканировать снова',
              onPressed: () async {
                await controller?.resumeCamera();
              },
              type: ButtonType.light,
            ),
          ],
        );
      }
    } catch (e) {
      // print('Error processing QR code: $e');
      if (!mounted) return;

      String errorMessage = 'Произошла ошибка при обработке QR-кода';

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }

      setState(() {
        _isProcessing = false;
      });

      controller?.pauseCamera();
      await BaseModal.show(
        context,
        message: errorMessage,
        width: MediaQuery.of(context).size.width - 40,
        buttons: [
          ModalButton(
            label: 'Сканировать снова',
            onPressed: () async {
              await controller?.resumeCamera();
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
              const CustomHeader(
                title: 'AINA QR',
                type: HeaderType.pop,
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
                  child: const Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Пожалуйста, подождите...',
                        style: TextStyle(
                          color: AppColors.secondary,
                        ),
                      )
                    ],
                  )),
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
    controller?.dispose();
    super.dispose();
  }
}
