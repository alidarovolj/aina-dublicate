import 'package:flutter/material.dart';

void printNavigationStack(BuildContext context) {
  // Получаем текущий навигатор
  final navigator = Navigator.of(context);

  print('🚀 Current Navigation Stack:');
  print('============================');

  // Получаем все маршруты в стеке
  navigator.popUntil((route) {
    print(
        '📍 ${route.settings.name ?? 'unnamed route'} (${route.runtimeType})');
    return true; // Продолжаем до конца стека
  });

  print('============================');
}
