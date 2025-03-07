import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/service.dart';
import 'package:aina_flutter/core/api/api_client.dart';

// Класс для услуг типа DEFAULT
class DefaultService extends Service {
  final String? timeUnit;
  final bool? isFixed;
  final String? capacity;

  DefaultService({
    required int id,
    required String title,
    String? description,
    required String type,
    String? subtype,
    int? parentId,
    int? categoryId,
    ServiceImage? image,
    List<ServiceImage>? gallery,
    int? price,
    this.timeUnit,
    this.isFixed,
    this.capacity,
  }) : super(
          id: id,
          title: title,
          description: description,
          type: type,
          subtype: subtype,
          parentId: parentId,
          sort: 0, // Значение по умолчанию
          image: image,
          gallery: gallery,
          price: price,
          categoryId: categoryId,
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
  print('🔄 Выполняется запрос на получение услуг типа DEFAULT...');

  try {
    final response =
        await api.dio.get('/api/promenade/services', queryParameters: {
      'type': 'DEFAULT',
    });

    print('✅ Получен ответ от API для услуг типа DEFAULT');
    print('📊 Статус ответа: ${response.statusCode}');

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      print('📋 Количество услуг типа DEFAULT: ${data.length}');

      // Создаем список для хранения преобразованных услуг
      final List<Service> services = [];

      // Обрабатываем каждый элемент отдельно
      for (var item in data) {
        try {
          // Используем специальный класс DefaultService
          final service = DefaultService.fromJson(item);
          services.add(service);
          print(
              '✅ Успешно преобразована услуга: ${service.title}, ID: ${service.id}');
        } catch (e) {
          print('❌ Ошибка при преобразовании услуги: $e');
          print('📄 Данные услуги: $item');
          // Пропускаем этот элемент и продолжаем с следующим
        }
      }

      print('🔄 Преобразовано в объекты Service: ${services.length}');
      return services;
    }

    print('❌ Ошибка в ответе API: success != true');
    throw Exception('Failed to load default services: success is not true');
  } catch (e) {
    print('❌ Исключение при загрузке услуг типа DEFAULT: $e');
    throw Exception('Failed to load default services: $e');
  }
});
