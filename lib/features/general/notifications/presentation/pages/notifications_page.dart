import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/providers/requests/notifications/notifications_provider.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'notifications.title'.tr(),
          style: GoogleFonts.lora(fontSize: 22, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => _buildSkeletonLoader(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'notifications.error'.tr(),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text('notifications.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (notificationsResponse) {
          // Безопасное получение списка уведомлений
          List? notifications;

          try {
            if (notificationsResponse.containsKey('data')) {
              final dataValue = notificationsResponse['data'];
              if (dataValue is List) {
                // Прямой список уведомлений
                notifications = dataValue;
              } else if (dataValue is Map && dataValue.containsKey('data')) {
                // Вложенная структура с data внутри data
                final dataList = dataValue['data'];
                if (dataList is List) {
                  notifications = dataList;
                }
              }
            }

            // Отладочный вывод
            print('Получены уведомления: ${notifications?.length}');
            if (notifications != null && notifications.isNotEmpty) {
              print('Первое уведомление: ${notifications.first}');
            }
          } catch (e) {
            print('Ошибка при получении списка уведомлений: $e');
          }

          if (notifications == null || notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'notifications.empty'.tr(),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Сортировка уведомлений по дате (от новых к старым)
          notifications.sort((a, b) {
            DateTime dateA = DateTime.now();
            DateTime dateB = DateTime.now();

            try {
              if (a is Map &&
                  a.containsKey('send_at') &&
                  a['send_at'] != null) {
                dateA = DateTime.parse(a['send_at'].toString());
              }
              if (b is Map &&
                  b.containsKey('send_at') &&
                  b['send_at'] != null) {
                dateB = DateTime.parse(b['send_at'].toString());
              }
            } catch (e) {
              print('Ошибка при сортировке дат: $e');
            }

            return dateB.compareTo(dateA); // От новых к старым
          });

          // Группировка уведомлений по дате
          final Map<String, List<dynamic>> groupedNotifications = {};

          for (var notification in notifications) {
            if (notification is Map &&
                notification.containsKey('send_at') &&
                notification['send_at'] != null) {
              try {
                final DateTime sendAt =
                    DateTime.parse(notification['send_at'].toString());
                final String dateKey = _formatDateForGrouping(sendAt);

                if (!groupedNotifications.containsKey(dateKey)) {
                  groupedNotifications[dateKey] = [];
                }

                groupedNotifications[dateKey]!.add(notification);
              } catch (e) {
                print('Ошибка при группировке уведомления: $e');
              }
            }
          }

          // Создаем список виджетов для отображения
          final List<Widget> notificationWidgets = [];

          groupedNotifications.forEach((dateKey, notificationsList) {
            // Добавляем заголовок с датой
            notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 16, bottom: 8),
                child: Center(
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            );

            // Добавляем уведомления для этой даты
            for (var notification in notificationsList) {
              notificationWidgets
                  .add(_buildNotificationCard(context, notification));
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notificationWidgets,
            ),
          );
        },
      ),
    );
  }

  // Форматирование даты для группировки
  String _formatDateForGrouping(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay.year == now.year &&
        dateDay.month == now.month &&
        dateDay.day == now.day) {
      return 'notifications.today'.tr();
    } else if (dateDay.year == yesterday.year &&
        dateDay.month == yesterday.month &&
        dateDay.day == yesterday.day) {
      return 'notifications.yesterday'.tr();
    } else {
      // Форматируем дату как "5 марта"
      // Используем DateFormat для локализованного отображения даты
      return DateFormat.MMMd().format(date);
    }
  }

  // Построение карточки уведомления
  Widget _buildNotificationCard(BuildContext context, dynamic notification) {
    // Безопасное получение заголовка
    String title = '';
    if (notification is Map && notification.containsKey('title')) {
      if (notification['title'] is String) {
        title = notification['title'] as String;
      } else if (notification['title'] is Map) {
        // Если title - это карта с ключами языков (для обратной совместимости)
        final titleMap = notification['title'] as Map;
        if (titleMap.containsKey(context.locale.languageCode)) {
          title = titleMap[context.locale.languageCode].toString();
        } else if (titleMap.containsKey('ru')) {
          title = titleMap['ru'].toString();
        } else if (titleMap.isNotEmpty) {
          title = titleMap.values.first.toString();
        }
      }
    }

    // Безопасное получение текста уведомления
    String body = '';
    if (notification is Map && notification.containsKey('body')) {
      if (notification['body'] is String) {
        body = notification['body'] as String;
      } else if (notification['body'] is Map) {
        // Если body - это карта с ключами языков (для обратной совместимости)
        final bodyMap = notification['body'] as Map;
        if (bodyMap.containsKey(context.locale.languageCode)) {
          body = bodyMap[context.locale.languageCode].toString();
        } else if (bodyMap.containsKey('ru')) {
          body = bodyMap['ru'].toString();
        } else if (bodyMap.isNotEmpty) {
          body = bodyMap.values.first.toString();
        }
      }
    }

    // Безопасное получение отправителя
    String sender = '';
    if (notification is Map &&
        notification.containsKey('sender') &&
        notification['sender'] != null) {
      sender = notification['sender'].toString();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.almostBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}
