import 'package:flutter/material.dart';
import 'services/epay_service.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';
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
    _configureEpay();
  }

  Future<void> _configureEpay() async {
    try {
      await _epayService.configure(
        merchantId: '67e34d63-102f-4bd1-898e-370781d0074d', // Test TerminalID
        merchantName: 'Test Store',
        clientId: 'test', // Test ClientID
        clientSecret:
            'yF587AV9Ms94qN2QShFzVR3vFnWkhjbAK3sG', // Test ClientSecret
      );
    } catch (e) {
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      final result = await _epayService.launchPayment(
        amount: 100.0, // Test amount - 100 KZT
        currency: 'KZT',
        description: 'Test payment',
        orderId: orderId,
      );

      if (result['isSuccessful'] == true) {
        final paymentReference = result['paymentReference'] as String;
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'payment.success'.tr(args: [paymentReference]),
            type: SnackBarType.success,
          );
        }
      } else {
        final errorMessage = result['errorMessage'] as String;
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'payment.failed'.tr(args: [errorMessage]),
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'payment.error'.tr(args: [e.toString()]),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
