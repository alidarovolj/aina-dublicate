import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrScannerModal extends ConsumerStatefulWidget {
  final int promotionId;

  const QrScannerModal({
    super.key,
    required this.promotionId,
  });

  static Future<void> show(BuildContext context, int promotionId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrScannerModal(promotionId: promotionId),
    );
  }

  @override
  ConsumerState<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends ConsumerState<QrScannerModal> {
  QRViewController? _controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent(authState)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Сканировать QR ВЫФВФВФЫВ',
            style: GoogleFonts.lora(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthState authState) {
    if (!authState.isAuthenticated) {
      return _buildAuthRequired();
    } else if (!authState.hasCompletedProfile) {
      return _buildProfileRequired();
    } else {
      return _buildScanner();
    }
  }

  Widget _buildAuthRequired() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Для сканирования чека пройдите регистрацию в приложении. Убедитесь в корректном заполнении имени и фамилии в профиле. Это обязательное условие участия в акции.',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppColors.textDarkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Зарегистрироваться',
            isFullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRequired() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Перед сканированием чека, пожалуйста, убедитесь в правильности имени и фамилии в профиле. Это обязательное условие участия в акции.',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppColors.textDarkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'В профиль',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/profile');
                  },
                  backgroundColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: CustomButton(
                  label: 'Сканировать',
                  isEnabled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    if (_controller == null) return const SizedBox.shrink();

    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.white,
            borderRadius: 12,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 250,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Text(
                  'Наведите камеру на QR-код',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
