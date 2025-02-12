import 'package:dio/dio.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_request.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:aina_flutter/features/coworking/domain/models/calendar_response.dart';
import 'package:aina_flutter/features/payment/services/epay_service.dart';
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

  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/aina/payments/pay',
        data: {
          'payable_type': 'ORDER',
          'payable_id': int.parse(orderId),
          'success_back_link': 'https://google.com',
          'failure_back_link': 'https://youtube.com',
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final paymentData = response.data['data'];

        final epayService = EpayService();
        await epayService.initializePayment(
          invoiceId: paymentData['invoiceId'],
          amount: paymentData['amount'],
          postLink: paymentData['postLink'],
          failurePostLink: paymentData['failurePostLink'],
          backLink: paymentData['backLink'],
          failureBackLink: paymentData['failureBackLink'],
          description: paymentData['description'],
          terminal: paymentData['terminal'],
          auth: paymentData['auth'],
          accountId: paymentData['accountId'],
          language: paymentData['language'] ?? 'rus',
        );

        return paymentData;
      }
      throw Exception('Failed to initiate payment: Invalid response format');
    } on DioException catch (e) {
      throw Exception('Failed to initiate payment: ${e.message}');
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
}
