import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/service.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:flutter/foundation.dart';

// Класс для услуг типа DEFAULT
class DefaultService extends Service {
  final String? timeUnit;
  final bool? isFixed;
  final String? capacity;

  DefaultService({
    required super.id,
    required super.title,
    super.description,
    required super.type,
    super.subtype,
    super.parentId,
    super.categoryId,
    super.image,
    super.gallery,
    super.price,
    this.timeUnit,
    this.isFixed,
    this.capacity,
  }) : super(
          sort: 0,
        );

  factory DefaultService.fromJson(Map<String, dynamic> json) {
    return DefaultService(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      subtype: json['subtype'] as String?,
      parentId: json['parent_id'] as int?,
      categoryId: json['category_id'] as int?,
      image: json['image'] != null
          ? ServiceImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      gallery: (json['gallery'] as List<dynamic>?)
          ?.map((e) => ServiceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: json['price'] as int?,
      timeUnit: json['time_unit'] as String?,
      isFixed: json['is_fixed'] as bool?,
      capacity: json['capacity'] as String?,
    );
  }
}

final servicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/api/promenade/services/categories');

  if (response.data['success'] == true) {
    final List<dynamic> data = response.data['data'];
    return data.map((item) => Service.fromJson(item)).toList();
  }

  throw Exception('Failed to load services');
});

final serviceDetailsProvider =
    FutureProvider.family<List<Service>, String>((ref, categoryId) async {
  final api = ApiClient();
  final response =
      await api.dio.get('/api/promenade/services', queryParameters: {
    'type': 'DEFAULT',
    'category_id': categoryId,
  });

  if (response.data['success'] == true) {
    final List<dynamic> data = response.data['data'];
    return data.map((item) => Service.fromJson(item)).toList();
  }

  throw Exception('Failed to load service details');
});

// Провайдер для получения услуг типа DEFAULT
final defaultServicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ApiClient();

  try {
    final response =
        await api.dio.get('/api/promenade/services', queryParameters: {
      'type': 'DEFAULT',
    });

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];

      // Создаем список для хранения преобразованных услуг
      final List<Service> services = [];

      // Обрабатываем каждый элемент отдельно
      for (var item in data) {
        try {
          // Используем специальный класс DefaultService
          final service = DefaultService.fromJson(item);
          services.add(service);
        } catch (e) {
          debugPrint('❌ Ошибка при преобразовании услуги: $e');
          debugPrint('📄 Данные услуги: $item');
          // Пропускаем этот элемент и продолжаем с следующим
        }
      }

      return services;
    }

    throw Exception('Failed to load default services: success is not true');
  } catch (e) {
    throw Exception('Failed to load default services: $e');
  }
});
