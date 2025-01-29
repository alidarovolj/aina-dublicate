import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

class AppSettings {
  final String whatsappLinkAinaMall;
  final String whatsappLinkPromenade;
  final String url1;
  final String url2;
  final String url3;
  final String supportEmailPromenade;
  final String webkassaStatus;

  AppSettings({
    required this.whatsappLinkAinaMall,
    required this.whatsappLinkPromenade,
    required this.url1,
    required this.url2,
    required this.url3,
    required this.supportEmailPromenade,
    required this.webkassaStatus,
  });

  factory AppSettings.fromJson(List<dynamic> data) {
    String findValue(String key) {
      final setting = data.firstWhere(
        (element) => element['key'] == key,
        orElse: () => {'value': ''},
      );
      return setting['value'] ?? '';
    }

    return AppSettings(
      whatsappLinkAinaMall: findValue('WHATSAPP_LINK_AINA_MALL'),
      whatsappLinkPromenade: findValue('WHATSAPP_LINK_PROMENADE'),
      url1: findValue('URL_1'),
      url2: findValue('URL_2'),
      url3: findValue('URL_3'),
      supportEmailPromenade: findValue('SUPPORT_EMAIL_PROMENADE'),
      webkassaStatus: findValue('WEBKASSA_STATUS'),
    );
  }
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  try {
    final response = await ApiClient().dio.get(
          '/api/aina/settings',
          options: Options(
            headers: {
              'Accept': 'application/json',
            },
          ),
        );

    if (response.statusCode != 200 || !response.data['success']) {
      throw Exception('Failed to fetch settings');
    }

    return AppSettings.fromJson(response.data['data']);
  } catch (e) {
    // print('Error fetching settings: $e');
    rethrow;
  }
});
