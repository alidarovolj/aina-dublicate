import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/restart_widget.dart';

final localeChangeProvider = StateProvider<int>((ref) => 0);

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  Future<void> _changeLanguage(
      BuildContext context, WidgetRef ref, String value) async {
    // Save the selected locale to SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', value);
    await prefs.setString('locale', value);

    // Set the locale in EasyLocalization and wait for it to be processed
    await context.setLocale(Locale(value));

    // Wait for the locale change to be processed
    await Future.delayed(const Duration(milliseconds: 50));

    // Force a complete app rebuild
    if (context.mounted) {
      // Update the state first
      ref.read(localeChangeProvider.notifier).state++;

      // Then restart the app
      RestartWidget.restartApp(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the locale change provider to rebuild on changes
    ref.watch(localeChangeProvider);

    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLength.tiny,
          vertical: AppLength.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              context.locale.languageCode.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ru',
          child: Row(
            children: [
              Text(
                'RU',
                style: TextStyle(
                  fontWeight: context.locale.languageCode == 'ru'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              if (context.locale.languageCode == 'ru')
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'kk',
          child: Row(
            children: [
              Text(
                'KK',
                style: TextStyle(
                  fontWeight: context.locale.languageCode == 'kk'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              if (context.locale.languageCode == 'kk')
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              Text(
                'EN',
                style: TextStyle(
                  fontWeight: context.locale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              if (context.locale.languageCode == 'en')
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        await _changeLanguage(context, ref, value);
      },
    );
  }
}
