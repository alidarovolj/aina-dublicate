import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _activeOrdersKey = 'activeOrders';
  static const String _inactiveOrdersKey = 'inactiveOrders';
  static const Duration _cacheValidity = Duration(minutes: 5);

  static Future<List<OrderResponse>> getCachedOrders(bool isActive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isActive ? _activeOrdersKey : _inactiveOrdersKey;

      final lastUpdateTimeStr = prefs.getString('${key}_lastUpdate');
      if (lastUpdateTimeStr == null) {
        return [];
      }

      final lastUpdateTime = DateTime.parse(lastUpdateTimeStr);
      if (DateTime.now().difference(lastUpdateTime) > _cacheValidity) {
        return [];
      }

      final ordersJson = prefs.getString(key);
      if (ordersJson == null) {
        return [];
      }

      final List<dynamic> ordersList = jsonDecode(ordersJson);
      return ordersList.map((json) => OrderResponse.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> cacheOrders(
      List<OrderResponse> orders, bool isActive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isActive ? _activeOrdersKey : _inactiveOrdersKey;

      final ordersList = orders.map((order) => order.toJson()).toList();
      await prefs.setString(key, jsonEncode(ordersList));
      await prefs.setString(
          '${key}_lastUpdate', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching orders: $e');
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeOrdersKey);
      await prefs.remove(_inactiveOrdersKey);
      await prefs.remove('${_activeOrdersKey}_lastUpdate');
      await prefs.remove('${_inactiveOrdersKey}_lastUpdate');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
