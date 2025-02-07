import 'package:dio/dio.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_request.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:aina_flutter/features/coworking/domain/models/calendar_response.dart';
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

  Future<OrderResponse> getOrderDetails(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/promenade/orders/$orderId',
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

  Future<String> initiatePayment(String orderId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/aina/payments/pay',
        data: {
          'payable_type': 'ORDER',
          'payable_id': int.parse(orderId),
          'success_back_link': 'aina://payment/success?order_id=$orderId',
          'failure_back_link': 'aina://payment/failure?order_id=$orderId',
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final paymentData = response.data['data'];
        final auth = paymentData['auth'];

        return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Epay Payment</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <script src="https://test-epay.homebank.kz/payform/payment-api.js"></script>
    <style>
      body {
        margin: 0;
        padding: 0;
        background: transparent;
      }
    </style>
    <script>
      document.addEventListener("DOMContentLoaded", () => {
        const paymentData = {
          invoiceId: "${paymentData['invoiceId']}",
          invoiceIdAlt: "${paymentData['invoiceId']}",
          backLink: "${paymentData['backLink']}",
          failureBackLink: "${paymentData['failureBackLink']}",
          postLink: "${paymentData['postLink']}",
          failurePostLink: "${paymentData['failurePostLink']}",
          language: "${paymentData['language']}",
          description: "${paymentData['description']}",
          accountId: "${paymentData['accountId']}",
          terminal: "${paymentData['terminal']}",
          amount: ${paymentData['amount']},
          currency: "${paymentData['currency']}",
          cardSave: true,
          data: ${jsonEncode({
              'statement': {
                'name': "User Name",
                'invoiceID': paymentData['invoiceId']
              }
            })},
          auth: ${jsonEncode(auth)},
        };

        halyk.showPaymentWidget(
          paymentData,
          (response) => {
            if (response.success) {
              window.location.href = "${paymentData['backLink']}";
            } else {
              window.location.href = "${paymentData['failureBackLink']}";
            }
          }
        );
      });
    </script>
  </head>
  <body>
  </body>
</html>
        ''';
      }
      throw Exception('Failed to initiate payment: Invalid response format');
    } on DioException catch (e) {
      throw Exception('Failed to initiate payment: ${e.message}');
    }
  }
}
