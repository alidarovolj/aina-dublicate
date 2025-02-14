import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('📱 Calling native configure method with:');
    debugPrint('   MerchantID: $merchantId');
    debugPrint('   MerchantName: $merchantName');
    debugPrint('   ClientID: $clientId');
    debugPrint(
        '   ClientSecret: ${clientSecret.substring(0, 5)}...'); // Only show first 5 chars for security

    try {
      await _channel.invokeMethod('configure', {
        'merchantId': merchantId,
        'merchantName': merchantName,
        'clientId': clientId,
        'clientSecret': clientSecret,
      });
      debugPrint('✅ Native configure method completed successfully');
    } on PlatformException catch (e) {
      debugPrint('❌ Native configure method failed:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Details: ${e.details}');
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
    debugPrint('📱 Calling native launchPayment method with:');
    debugPrint('   Amount: $amount');
    debugPrint('   Currency: $currency');
    debugPrint('   Description: $description');
    debugPrint('   OrderID: $orderId');

    try {
      final result = await _channel.invokeMethod('launchPayment', {
        'amount': amount,
        'currency': currency,
        'description': description,
        'orderId': orderId,
      });

      debugPrint('✅ Native launchPayment method returned: $result');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('❌ Native launchPayment method failed:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Details: ${e.details}');
      throw Exception('Payment failed: ${e.message}');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus({
    required String paymentReference,
  }) async {
    debugPrint('📱 Calling native checkPaymentStatus method with:');
    debugPrint('   PaymentReference: $paymentReference');

    try {
      final result = await _channel.invokeMethod('checkPaymentStatus', {
        'paymentReference': paymentReference,
      });

      debugPrint('✅ Native checkPaymentStatus method returned: $result');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('❌ Native checkPaymentStatus method failed:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Details: ${e.details}');
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

      debugPrint('Initializing payment with data: $paymentData');

      final result =
          await _channel.invokeMethod('initializePayment', paymentData);
      debugPrint('Payment initialization result: $result');

      if (result == null) {
        throw PlatformException(
          code: 'PAYMENT_ERROR',
          message: 'Payment initialization failed with no error details',
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Payment initialization failed: ${e.message}');
      debugPrint('Error code: ${e.code}');
      debugPrint('Error details: ${e.details}');
      throw Exception('Failed to initialize payment: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error during payment initialization: $e');
      throw Exception('Unexpected error during payment initialization: $e');
    }
  }
}
