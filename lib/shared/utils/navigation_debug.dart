import 'package:flutter/material.dart';

void printNavigationStack(BuildContext context) {
  // Получаем текущий навигатор
  final navigator = Navigator.of(context);

  // Получаем все маршруты в стеке
  navigator.popUntil((route) {
    return true; // Продолжаем до конца стека
  });
}
