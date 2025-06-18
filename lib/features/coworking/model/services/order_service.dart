import 'package:dio/dio.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/features/coworking/model/models/order_request.dart';
import 'package:aina_flutter/features/coworking/model/models/order_response.dart';
import 'package:aina_flutter/features/coworking/model/models/calendar_response.dart';
import 'package:aina_flutter/features/coworking/model/models/pre_calculation_response.dart';
import 'dart:convert';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  Future<OrderResponse> createOrder(OrderRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/promenade/orders',
        data: request.toJson(),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return OrderResponse.fromJson(response.data['data']);
      }
      throw Exception('Failed to create order: Invalid response format');
    } on DioException catch (e) {
      throw Exception('Failed to create order: ${e.message}');
    }
  }

  Future<OrderResponse> getOrderDetails(String orderId,
      {bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/promenade/orders/$orderId',
        options: Options(
          headers: forceRefresh ? {'force-refresh': 'true'} : null,
        ),
      );
      return OrderResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to get order details: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createPayment(
      String orderId, Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/promenade/orders/$orderId/payment',
        data: paymentData,
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception('Failed to create payment: ${e.message}');
    }
  }

  Future<String> getOrderQRHtml(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
          '/api/promenade/orders/$orderId/download-visitor-qr',
          queryParameters: {
            'html': true,
          });
      // print('QR HTML Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get order QR: ${e.message}');
    }
  }

  Future<CalendarResponse> getCalendar(
      String searchDate, String serviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/promenade/orders/calendar',
        queryParameters: {
          'search_date': searchDate,
          'service_id': serviceId,
        },
      );
      return CalendarResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get calendar: ${e.message}');
    }
  }

  Future<String> initiatePayment(String orderId, String paymentMethodId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/aina/payments/pay',
        data: {
          'payable_type': 'ORDER',
          'payable_id': int.parse(orderId),
          'payment_method_id': paymentMethodId,
          'success_back_link':
              'https://app.aina-fashion.kz/success-payment?order_id=$orderId',
          'failure_back_link':
              'https://app.aina-fashion.kz/failure-payment?order_id=$orderId',
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final paymentData = response.data['data'];

        // If this is a quota payment (no payment data returned)
        if (paymentData == null || paymentData.isEmpty) {
          return '';
        }

        final auth = paymentData['auth'];

        return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta http-equiv="Content-Security-Policy" content="default-src * 'unsafe-inline' 'unsafe-eval' data: gap:">
    <title>Epay Payment</title>
    <script src="https://test-epay.homebank.kz/payform/payment-api.js"></script>
    <style>
      body {
        margin: 0;
        padding: 0;
        background: transparent;
        -webkit-touch-callout: none;
        -webkit-user-select: none;
        -khtml-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
        -webkit-tap-highlight-color: transparent;
      }
      #loading {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        font-family: system-ui;
        z-index: 9999;
      }
      #payment-container {
        min-height: 100vh;
        width: 100%;
      }
      #close-button {
        position: fixed;
        top: 16px;
        right: 16px;
        z-index: 10000;
        background: rgba(0, 0, 0, 0.5);
        color: white;
        border: none;
        border-radius: 50%;
        width: 32px;
        height: 32px;
        font-size: 18px;
        line-height: 1;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
      }
    </style>
  </head>
  <body>
    <div id="payment-container"></div>
    <div id="loading"></div>

    <script>
      // Prevent zooming
      document.addEventListener('touchmove', function(event) {
        if (event.scale !== 1) {
          event.preventDefault();
        }
      }, { passive: false });

      function handleClose() {
        const failureUrl = "${paymentData['failureBackLink'] ?? ''}";
        console.log('Handling close action, redirecting to:', failureUrl);
        if (failureUrl) {
          try {
            // First try to use the native close if available
            if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler('closePayment');
            }
            // Then redirect
            window.location.href = failureUrl;
          } catch (error) {
            console.error('Error in handleClose:', error);
            // Fallback to direct location change
            window.location.href = failureUrl;
          }
        }
      }

      function handlePaymentError(error) {
        console.error('Payment error:', error);
        handleClose();
      }

      // Check if script is loaded
      function checkScriptLoaded() {
        return new Promise((resolve) => {
          if (window.halyk) {
            resolve(true);
          } else {
            setTimeout(() => resolve(checkScriptLoaded()), 100);
          }
        });
      }

      document.addEventListener("DOMContentLoaded", async () => {
        try {
          // Wait for script to load
          await checkScriptLoaded();

          const paymentData = {
            invoiceId: "${paymentData['invoiceId'] ?? ''}",
            invoiceIdAlt: "${paymentData['invoiceIdAlt'] ?? ''}",
            backLink: "${paymentData['backLink'] ?? ''}",
            failureBackLink: "${paymentData['failureBackLink'] ?? ''}",
            postLink: "${paymentData['postLink'] ?? ''}",
            failurePostLink: "${paymentData['failurePostLink'] ?? ''}",
            language: "${paymentData['language'] ?? 'rus'}",
            description: "${paymentData['description']?.replaceAll('"', '\\"') ?? ''}",
            accountId: "${paymentData['accountId'] ?? ''}",
            terminal: "${paymentData['terminal'] ?? ''}",
            amount: ${paymentData['amount'] ?? 0},
            currency: "${paymentData['currency'] ?? 'KZT'}",
            cardSave: true,
            data: ${jsonEncode({
              'statement': {
                'invoiceID': paymentData['invoiceId'] ?? '',
                'amount': paymentData['amount']?.toString() ?? '0'
              }
            })},
            auth: ${jsonEncode(auth ?? {})},
          };

          console.log('Initializing payment with data:', paymentData);

          setTimeout(() => {
            try {
              halyk.showPaymentWidget(paymentData, (response) => {
                console.log('Payment response:', response);
                if (response && response.success) {
                  window.location.href = paymentData.backLink || "${paymentData['backLink'] ?? ''}";
                } else {
                  handlePaymentError(response);
                }
              });
              document.getElementById('loading').style.display = 'none';
            } catch (error) {
              console.error('Error showing payment widget:', error);
              handlePaymentError(error);
            }
          }, 1000);
        } catch (error) {
          console.error('Error in payment initialization:', error);
          handlePaymentError(error);
        }
      });

      window.onerror = function(message, source, lineno, colno, error) {
        console.error('Global error:', { message, source, lineno, colno, error });
        handlePaymentError(error);
        return true;
      };

      // Handle back button press
      window.onpopstate = function() {
        handleClose();
      };

      // Handle escape key
      document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
          handleClose();
        }
      });

      // Add event listener for Android back button
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onBackPressed', () => {
          handleClose();
          return true;
        });
      }
    </script>
  </body>
</html>
        ''';
      }
      throw Exception('Failed to initiate payment: Invalid response format');
    } on DioException catch (e) {
      throw Exception('Failed to initiate payment: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> initiateContractPayment(
      String orderId, String paymentMethodId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/aina/payments/pay',
        data: {
          'payable_type': 'ORDER',
          'payable_id': int.parse(orderId),
          'payment_method_id': paymentMethodId,
          'success_back_link': '',
          'failure_back_link': '',
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
          'Failed to initiate contract payment: Invalid response format');
    } on DioException catch (e) {
      throw Exception('Failed to initiate contract payment: ${e.message}');
    }
  }

  Future<void> payWithQuota(String orderId) async {
    try {
      await _apiClient.dio.post(
        '/api/promenade/orders/$orderId/pay-with-quota',
      );
    } on DioException catch (e) {
      throw Exception('Failed to pay with quota: ${e.message}');
    }
  }

  Future<List<dynamic>> getOrders({
    required String stateGroup,
    bool forceRefresh = false,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/promenade/orders',
      queryParameters: {
        'per_page': 10,
        'page': 1,
        'state_group': stateGroup,
      },
      options: Options(
        headers: forceRefresh ? {'force-refresh': 'true'} : null,
      ),
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      return response.data['data'];
    }
    return [];
  }

  Future<PreCalculationResponse> preCalculateOrder({
    required int serviceId,
    required String startAt,
    required String endAt,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/promenade/orders/pre-calc',
        data: {
          'service_id': serviceId,
          'start_at': startAt,
          'end_at': endAt,
        },
      );

      if (response.data['success'] == true) {
        return PreCalculationResponse.fromJson(response.data['data']);
      }

      throw Exception('Failed to pre-calculate order');
    } catch (e) {
      rethrow;
    }
  }
}


// import 'package:dio/dio.dart';
// import 'package:aina_flutter/core/api/api_client.dart';
// import 'package:aina_flutter/features/coworking/model/models/order_request.dart';
// import 'package:aina_flutter/features/coworking/model/models/order_response.dart';
// import 'package:aina_flutter/features/coworking/model/models/calendar_response.dart';
// import 'package:aina_flutter/features/payment/services/epay_service.dart';
// import 'dart:convert';

// class OrderService {
//   final ApiClient _apiClient;

//   OrderService(this._apiClient);

//   Future<OrderResponse> createOrder(OrderRequest request) async {
//     try {
//       final response = await _apiClient.dio.post(
//         '/api/promenade/orders',
//         data: request.toJson(),
//       );

//       if (response.data['success'] == true && response.data['data'] != null) {
//         return OrderResponse.fromJson(response.data['data']);
//       }
//       throw Exception('Failed to create order: Invalid response format');
//     } on DioException catch (e) {
//       throw Exception('Failed to create order: ${e.message}');
//     }
//   }

//   Future<OrderResponse> getOrderDetails(String orderId) async {
//     try {
//       final response = await _apiClient.dio.get(
//         '/api/promenade/orders/$orderId',
//       );
//       return OrderResponse.fromJson(response.data['data']);
//     } on DioException catch (e) {
//       throw Exception('Failed to get order details: ${e.message}');
//     }
//   }

//   Future<Map<String, dynamic>> createPayment(
//       String orderId, Map<String, dynamic> paymentData) async {
//     try {
//       final response = await _apiClient.dio.post(
//         '/api/promenade/orders/$orderId/payment',
//         data: paymentData,
//       );
//       return response.data['data'];
//     } on DioException catch (e) {
//       throw Exception('Failed to create payment: ${e.message}');
//     }
//   }

//   Future<String> getOrderQRHtml(String orderId) async {
//     try {
//       final response = await _apiClient.dio.get(
//           '/api/promenade/orders/$orderId/download-visitor-qr',
//           queryParameters: {
//             'html': true,
//           });
//       // print('QR HTML Response: ${response.data}');
//       return response.data;
//     } on DioException catch (e) {
//       throw Exception('Failed to get order QR: ${e.message}');
//     }
//   }

//   Future<CalendarResponse> getCalendar(
//       String searchDate, String serviceId) async {
//     try {
//       final response = await _apiClient.dio.get(
//         '/api/promenade/orders/calendar',
//         queryParameters: {
//           'search_date': searchDate,
//           'service_id': serviceId,
//         },
//       );
//       return CalendarResponse.fromJson(response.data);
//     } on DioException catch (e) {
//       throw Exception('Failed to get calendar: ${e.message}');
//     }
//   }

//   Future<Map<String, dynamic>> initiatePayment(String orderId) async {
//     try {
//       final response = await _apiClient.dio.post(
//         '/api/aina/payments/pay',
//         data: {
//           'payable_type': 'ORDER',
//           'payable_id': int.parse(orderId),
//           'success_back_link': 'https://google.com',
//           'failure_back_link': 'https://youtube.com',
//         },
//       );

//       if (response.data['success'] == true && response.data['data'] != null) {
//         final paymentData = response.data['data'];

//         final epayService = EpayService();
//         await epayService.initializePayment(
//           invoiceId: paymentData['invoiceId'],
//           amount: paymentData['amount'],
//           postLink: paymentData['postLink'],
//           failurePostLink: paymentData['failurePostLink'],
//           backLink: paymentData['backLink'],
//           failureBackLink: paymentData['failureBackLink'],
//           description: paymentData['description'],
//           terminal: paymentData['terminal'],
//           auth: paymentData['auth'],
//           accountId: paymentData['accountId'],
//           language: paymentData['language'] ?? 'rus',
//         );

//         return paymentData;
//       }
//       throw Exception('Failed to initiate payment: Invalid response format');
//     } on DioException catch (e) {
//       throw Exception('Failed to initiate payment: ${e.message}');
//     }
//   }

//   Future<List<dynamic>> getOrders({
//     required String stateGroup,
//     bool forceRefresh = false,
//   }) async {
//     final response = await _apiClient.dio.get(
//       '/api/promenade/orders',
//       queryParameters: {
//         'per_page': 10,
//         'page': 1,
//         'state_group': stateGroup,
//       },
//       options: Options(
//         headers: forceRefresh ? {'force-refresh': 'true'} : null,
//       ),
//     );

//     if (response.data['success'] == true && response.data['data'] != null) {
//       return response.data['data'];
//     }
//     return [];
//   }
// }

