import 'package:flutter/services.dart';

class EpayService {
  static const MethodChannel _channel = MethodChannel('kz.aina/epay');

  // Test credentials
  static const String testClientId = 'test';
  static const String testClientSecret = 'yF587AV9Ms94qN2QShFzVR3vFnWkhjbAK3sG';
  static const String testTerminalId = '67e34d63-102f-4bd1-898e-370781d0074d';

  // Configuration for the SDK
  Future<void> configure({
    required String merchantId,
    required String merchantName,
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      await _channel.invokeMethod('configure', {
        'merchantId': merchantId,
        'merchantName': merchantName,
        'clientId': clientId,
        'clientSecret': clientSecret,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to configure Epay SDK: ${e.message}');
    }
  }

  // Launch payment screen
  Future<Map<String, dynamic>> launchPayment({
    required double amount,
    required String currency,
    required String description,
    String? orderId,
  }) async {
    try {
      final result = await _channel.invokeMethod('launchPayment', {
        'amount': amount,
        'currency': currency,
        'description': description,
        'orderId': orderId,
      });

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Payment failed: ${e.message}');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus({
    required String paymentReference,
  }) async {
    try {
      final result = await _channel.invokeMethod('checkPaymentStatus', {
        'paymentReference': paymentReference,
      });

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to check payment status: ${e.message}');
    }
  }

  Future<void> initializePayment({
    required String invoiceId,
    required int amount,
    required String postLink,
    required String failurePostLink,
    required String backLink,
    required String failureBackLink,
    required String description,
    String terminal = testTerminalId,
    Map<String, dynamic>? auth,
    String? accountId,
    String language = 'rus',
  }) async {
    try {
      // Use test credentials if auth is not provided
      final Map<String, dynamic> testAuth = {
        'access_token': testClientSecret,
        // 'client_id': testClientId,
        'client_id': "test",
      };

      final Map<String, dynamic> paymentData = {
        'invoiceId': invoiceId,
        'amount': amount,
        'currency': 'KZT',
        'postLink': postLink,
        'failurePostLink': failurePostLink,
        'backLink': backLink,
        'failureBackLink': failureBackLink,
        'description': description,
        'terminal': terminal,
        'auth': auth ?? testAuth,
        'accountId': accountId ?? '1',
        'language': language,
        'isTestMode': true, // Force test mode
      };

      final result =
          await _channel.invokeMethod('initializePayment', paymentData);

      if (result == null) {
        throw PlatformException(
          code: 'PAYMENT_ERROR',
          message: 'Payment initialization failed with no error details',
        );
      }
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize payment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during payment initialization: $e');
    }
  }
}
