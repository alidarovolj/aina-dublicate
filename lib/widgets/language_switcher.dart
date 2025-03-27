import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/restart_widget.dart';
import 'package:aina_flutter/shared/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final localeChangeProvider = StateProvider<int>((ref) => 0);
final isLanguageExpandedProvider = StateProvider<bool>((ref) => false);

class LanguageSwitcher extends ConsumerWidget {
  final String source;

  const LanguageSwitcher({
    super.key,
    this.source = 'main',
  });

  void _logLanguageChange(String languageCode, String source) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'change_lang_click',
      eventProperties: {
        'lang': languageCode,
        'source': source,
      },
    );
  }

  Future<void> _changeLanguage(
      BuildContext context, WidgetRef ref, String value) async {
    _logLanguageChange(value, source);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', value);
    await prefs.setString('locale', value);
    await context.setLocale(Locale(value));
    await Future.delayed(const Duration(milliseconds: 50));

    if (context.mounted) {
      ref.read(localeChangeProvider.notifier).state++;
      ref.read(isLanguageExpandedProvider.notifier).state = false;
      RestartWidget.restartApp(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeChangeProvider);
    final currentLocale = context.locale.languageCode;
    final isExpanded = ref.watch(isLanguageExpandedProvider);

    List<String> getLanguageOrder() {
      final languages = ['kk', 'en', 'ru'];
      languages.remove(currentLocale);
      return languages;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isExpanded ? 92 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: getLanguageOrder()
                    .map((code) => _buildLanguageButton(
                          context,
                          ref,
                          code.toUpperCase(),
                          code,
                          currentLocale,
                          isCurrentLanguage: false,
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildLanguageButton(
            context,
            ref,
            currentLocale.toUpperCase(),
            currentLocale,
            currentLocale,
            isCurrentLanguage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, WidgetRef ref, String label,
      String code, String currentLocale,
      {required bool isCurrentLanguage}) {
    final isExpanded = ref.watch(isLanguageExpandedProvider);

    return InkWell(
      onTap: () {
        if (isCurrentLanguage) {
          ref.read(isLanguageExpandedProvider.notifier).state =
              !ref.read(isLanguageExpandedProvider);
        } else {
          _changeLanguage(context, ref, code);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isCurrentLanguage && isExpanded
              ? Colors.white
              : Colors.transparent,
          border: isExpanded
              ? Border.all(
                  color: Colors.white,
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isCurrentLanguage && isExpanded ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: isCurrentLanguage ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
