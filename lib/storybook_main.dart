import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'storybook.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ru'),
        Locale('kk'),
        Locale('en'),
      ],
      path: 'lib/app/assets/translations',
      fallbackLocale: const Locale('ru'),
      child: const StorybookApp(),
    ),
  );
}
