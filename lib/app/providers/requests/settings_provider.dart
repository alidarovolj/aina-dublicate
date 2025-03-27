import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

class SettingFile {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  SettingFile({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory SettingFile.fromJson(Map<String, dynamic> json) {
    return SettingFile(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      url: json['url'] as String,
      urlOriginal: json['urlOriginal'] as String,
      orderColumn: json['order_column'] as int,
      collectionName: json['collection_name'] as String,
    );
  }
}

class AppSettings {
  final String whatsappLinkAinaMall;
  final String whatsappLinkPromenade;
  final String supportEmailPromenade;
  final String url1;
  final String url2;
  final String url3;
  final String webkassaStatus;
  final SettingFile? confidentialityAgreementFile;
  final SettingFile? rulesCoworkingSpaceFile;
  final SettingFile? userAgreementFile;
  final SettingFile? publicOfferFile;

  AppSettings({
    required this.whatsappLinkAinaMall,
    required this.whatsappLinkPromenade,
    required this.supportEmailPromenade,
    required this.url1,
    required this.url2,
    required this.url3,
    required this.webkassaStatus,
    this.confidentialityAgreementFile,
    this.rulesCoworkingSpaceFile,
    this.userAgreementFile,
    this.publicOfferFile,
  });

  factory AppSettings.fromJson(List<dynamic> data) {
    Map<String, dynamic> findSetting(String key) {
      return data.firstWhere(
        (element) => element['key'] == key,
        orElse: () => {'value': '', 'file': null},
      );
    }

    String getValue(String key) {
      final setting = findSetting(key);
      return setting['value'] ?? '';
    }

    SettingFile? getFile(String key) {
      final setting = findSetting(key);
      if (setting['file'] != null) {
        return SettingFile.fromJson(setting['file']);
      }
      return null;
    }

    return AppSettings(
      whatsappLinkAinaMall: getValue('WHATSAPP_LINK_AINA_MALL'),
      whatsappLinkPromenade: getValue('WHATSAPP_LINK_PROMENADE'),
      supportEmailPromenade: getValue('SUPPORT_EMAIL_PROMENADE'),
      url1: getValue('URL_1'),
      url2: getValue('URL_2'),
      url3: getValue('URL_3'),
      webkassaStatus: getValue('WEBKASSA_STATUS'),
      confidentialityAgreementFile: getFile('CONFIDENTIALITY_AGREEMENT_FILE'),
      rulesCoworkingSpaceFile: getFile('RULES_COWORKING_SPACE_FILE'),
      userAgreementFile: getFile('USER_AGREEMENT_FILE'),
      publicOfferFile: getFile('PUBLIC_OFFER_FILE'),
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
    rethrow;
  }
});
