import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class SavedCardsService {
  final Dio _dio;

  SavedCardsService(this._dio);

  /// Получает список сохраненных карт для заказа
  Future<List<SavedCard>> getSavedCards({
    required String payableType,
    required int payableId,
    required int paymentMethodId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/aina/payments/cards',
        data: {
          'payable_type': payableType,
          'payable_id': payableId,
          'payment_method_id': paymentMethodId,
        },
      );

      debugPrint('📱 SAVED CARDS API RESPONSE:');
      debugPrint('   Success: ${response.data['success']}');
      debugPrint('   Message: ${response.data['message']}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final cards = data?['cards'] ?? [];
        debugPrint('   Cards count: ${cards.length}');
        for (int i = 0; i < cards.length; i++) {
          final card = cards[i];
          debugPrint(
              '   Card $i: ${card['card_mask']} (${card['payer_name']})');
        }
      }

      if (response.data['success'] == true) {
        final Map<String, dynamic> data = response.data['data'] ?? {};
        final List<dynamic> cardsData = data['cards'] ?? [];
        return cardsData
            .map((cardJson) => SavedCard.fromJson(cardJson))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load saved cards');
      }
    } catch (e) {
      debugPrint('❌ Error getting saved cards: $e');
      rethrow;
    }
  }

  /// Удаляет сохраненную карту
  Future<bool> deleteCard({
    required String cardId,
    required String payableType,
    required int payableId,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/aina/payments/cards',
        data: {
          'card_id': cardId,
          'payable_type': payableType,
          'payable_id': payableId,
        },
      );

      debugPrint('🗑️ DELETE CARD API RESPONSE:');
      debugPrint('   Success: ${response.data['success']}');
      debugPrint('   Message: ${response.data['message']}');

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error deleting card: $e');
      rethrow;
    }
  }
}

/// Модель сохраненной карты
class SavedCard {
  final String id;
  final String token;
  final String cardMask;
  final String payerName;
  final String reference;
  final String createdDate;
  final bool active;

  SavedCard({
    required this.id,
    required this.token,
    required this.cardMask,
    required this.payerName,
    required this.reference,
    required this.createdDate,
    required this.active,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] ?? '',
      token: json['token'] ?? '',
      cardMask: json['card_mask'] ?? '',
      payerName: json['payer_name'] ?? '',
      reference: json['reference'] ?? '',
      createdDate: json['created_date'] ?? '',
      active: json['active'] ?? false,
    );
  }

  /// Определяем тип карты по маске номера
  String get cardType {
    if (cardMask.startsWith('4')) {
      return 'visa';
    } else if (cardMask.startsWith('5') || cardMask.startsWith('2')) {
      return 'mastercard';
    } else {
      return 'unknown';
    }
  }

  /// Получаем иконку карты по типу
  String get cardIcon {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'lib/app/assets/icons/visa.svg';
      case 'mastercard':
        return 'lib/app/assets/icons/mastercard.svg';
      default:
        return 'lib/app/assets/icons/credit-card.svg';
    }
  }

  /// Форматированное отображение номера карты
  String get maskedNumber => cardMask;
}

/// Provider для сервиса сохраненных карт
final savedCardsServiceProvider = Provider<SavedCardsService>(
  (ref) => SavedCardsService(ApiClient().dio),
);

/// Provider для получения сохраненных карт
final savedCardsProvider =
    FutureProvider.family<List<SavedCard>, SavedCardsParams>(
  (ref, params) async {
    final service = ref.read(savedCardsServiceProvider);
    return await service.getSavedCards(
      payableType: params.payableType,
      payableId: params.payableId,
      paymentMethodId: params.paymentMethodId,
    );
  },
);

/// Параметры для получения сохраненных карт
class SavedCardsParams {
  final String payableType;
  final int payableId;
  final int paymentMethodId;

  SavedCardsParams({
    required this.payableType,
    required this.payableId,
    required this.paymentMethodId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCardsParams &&
          runtimeType == other.runtimeType &&
          payableType == other.payableType &&
          payableId == other.payableId &&
          paymentMethodId == other.paymentMethodId;

  @override
  int get hashCode =>
      payableType.hashCode ^ payableId.hashCode ^ paymentMethodId.hashCode;
}
