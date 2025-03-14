import 'package:flutter/material.dart';
import 'services/epay_service.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _epayService = EpayService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 PaymentPage initialized');
    _configureEpay();
  }

  Future<void> _configureEpay() async {
    debugPrint('⚙️ Configuring Epay SDK...');
    try {
      await _epayService.configure(
        merchantId: '67e34d63-102f-4bd1-898e-370781d0074d', // Test TerminalID
        merchantName: 'Test Store',
        clientId: 'test', // Test ClientID
        clientSecret:
            'yF587AV9Ms94qN2QShFzVR3vFnWkhjbAK3sG', // Test ClientSecret
      );
      debugPrint('✅ Epay SDK configured successfully');
    } catch (e) {
      debugPrint('❌ Failed to configure Epay SDK: $e');
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'payment.configure_error'.tr(args: [e.toString()]),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _makePayment() async {
    if (_isLoading) {
      debugPrint('⚠️ Payment already in progress');
      return;
    }

    debugPrint('💳 Starting payment process...');
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📤 Launching payment with parameters:');
      debugPrint('   Amount: 100.0 KZT');
      debugPrint('   Description: Test payment');
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('   OrderID: $orderId');

      final result = await _epayService.launchPayment(
        amount: 100.0, // Test amount - 100 KZT
        currency: 'KZT',
        description: 'Test payment',
        orderId: orderId,
      );

      debugPrint('📥 Received payment result: $result');

      if (result['isSuccessful'] == true) {
        final paymentReference = result['paymentReference'] as String;
        debugPrint('✅ Payment successful! Reference: $paymentReference');
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'payment.success'.tr(args: [paymentReference]),
            type: SnackBarType.success,
          );
        }
      } else {
        final errorMessage = result['errorMessage'] as String;
        debugPrint('❌ Payment failed: $errorMessage');
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'payment.failed'.tr(args: [errorMessage]),
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Payment error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'payment.error'.tr(args: [e.toString()]),
          type: SnackBarType.error,
        );
      }
    } finally {
      debugPrint('🏁 Payment process finished');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building PaymentPage UI');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _makePayment,
                child: const Text('Pay 100 KZT'),
              ),
            const SizedBox(height: 16),
            const Text(
              'This is a test payment using Epay SDK\n'
              'Amount: 100 KZT',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
