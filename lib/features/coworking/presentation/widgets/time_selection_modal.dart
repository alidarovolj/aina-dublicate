import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_tariff_details.dart';
import 'package:aina_flutter/features/conference/domain/services/conference_service.dart';
import 'package:aina_flutter/features/conference/presentation/pages/order_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class TimeSelectionModal extends StatefulWidget {
  final DateTime date;
  final CoworkingTariffDetails tariffDetails;
  final Function(String startTime, String endTime, int total)? onTimeSelected;
  final bool isConference;

  const TimeSelectionModal({
    Key? key,
    required this.date,
    required this.tariffDetails,
    this.onTimeSelected,
    this.isConference = false,
  }) : super(key: key);

  @override
  State<TimeSelectionModal> createState() => _TimeSelectionModalState();
}

class _TimeSelectionModalState extends State<TimeSelectionModal> {
  String? selectedStartTime;
  String? selectedEndTime;
  bool selectingStartTime = true;
  Map<DateTime, List<String>> timeSlotsByDay = {};
  int? calculatedTotal;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    final timeStep =
        widget.tariffDetails.timeStep ?? 0.5; // 30 минут по умолчанию

    // Генерируем слоты для трех дней
    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final currentDate = widget.date.add(Duration(days: dayOffset));
      final slots = <String>[];

      for (var hour = 0; hour < 24; hour++) {
        for (var minute = 0.0; minute < 60; minute += (timeStep * 60)) {
          final time = DateTime(2024, 1, 1, hour, minute.toInt());
          slots.add(DateFormat('HH:mm').format(time));
        }
      }

      setState(() {
        timeSlotsByDay[currentDate] = slots;
      });
    }
  }

  void _selectTime(String time, DateTime date) {
    if (selectingStartTime) {
      // Если выбираем начальное время
      final fullDateTime = '${DateFormat('yyyy-MM-dd').format(date)} $time';
      if (fullDateTime == selectedStartTime) {
        // Если кликнули на то же время - сбрасываем выбор
        setState(() {
          selectedStartTime = null;
          selectedEndTime = null;
          calculatedTotal = null;
          selectingStartTime = true;
        });
        return;
      }
      setState(() {
        selectedStartTime = fullDateTime;
        selectedEndTime = null;
        calculatedTotal = null;
        selectingStartTime = false;
      });
    } else {
      // Если выбираем конечное время
      final fullDateTime = '${DateFormat('yyyy-MM-dd').format(date)} $time';
      final start = DateTime.parse('$selectedStartTime:00');
      final end = DateTime.parse('$fullDateTime:00');

      // Проверка минимальной длительности
      final minDuration = widget.tariffDetails.minDuration ?? 2;
      final difference = end.difference(start).inHours;

      if (difference < minDuration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Минимальное время бронирования: $minDuration часа'),
          ),
        );
        return;
      }

      if (fullDateTime == selectedEndTime) {
        // Если кликнули на то же конечное время - возвращаемся к выбору начального времени
        setState(() {
          selectedEndTime = null;
          calculatedTotal = null;
          selectingStartTime = true;
        });
        return;
      }

      setState(() {
        selectedEndTime = fullDateTime;
        calculatedTotal = widget.tariffDetails.price * difference;
        selectingStartTime = true;
      });
    }
  }

  String _formatSelectedDateTime(String? fullDateTime) {
    if (fullDateTime == null) return 'Не выбрано';
    final dateTime = DateTime.parse('${fullDateTime}:00');
    return '${DateFormat('dd MMMM yyyy', 'ru').format(dateTime)} ${DateFormat('HH:mm').format(dateTime)}';
  }

  bool _isTimeSlotAvailable(DateTime date, String time) {
    final now = DateTime.now();
    final slotDateTime =
        DateTime.parse('${DateFormat('yyyy-MM-dd').format(date)} $time:00');

    // Если дата раньше сегодняшней - слот недоступен
    if (date.year < now.year ||
        (date.year == now.year && date.month < now.month) ||
        (date.year == now.year &&
            date.month == now.month &&
            date.day < now.day)) {
      return false;
    }

    // Если это сегодняшний день, проверяем время
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return slotDateTime.isAfter(now);
    }

    return true;
  }

  void _onConfirm() {
    if (selectedStartTime != null && selectedEndTime != null) {
      if (widget.isConference) {
        Navigator.of(context).pop(); // Close modal
        context.pushNamed(
          'coworking_calendar',
          pathParameters: {
            'id': widget.tariffDetails.id.toString(),
            'tariffId': widget.tariffDetails.id.toString()
          },
          queryParameters: {
            'type': 'conference',
            'startTime': '$selectedStartTime:00',
            'endTime': '$selectedEndTime:00',
          },
        );
      } else {
        widget.onTimeSelected?.call(
          '$selectedStartTime:00',
          '$selectedEndTime:00',
          calculatedTotal ?? 0,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Верхний блок с заголовком
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Выберите время (мин. ${widget.tariffDetails.minDuration ?? 2} ч.)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Time selection toggle
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectingStartTime
                                ? AppColors.secondary
                                : Colors.grey,
                            width: selectingStartTime ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Начало',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              selectedStartTime != null
                                  ? _formatSelectedDateTime(selectedStartTime)
                                  : 'Не выбрано',
                              style: const TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: !selectingStartTime
                                ? AppColors.secondary
                                : Colors.grey,
                            width: !selectingStartTime ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Конец',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              selectedEndTime != null
                                  ? _formatSelectedDateTime(selectedEndTime)
                                  : 'Не выбрано',
                              style: const TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time slots grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: timeSlotsByDay.length,
              itemBuilder: (context, dayIndex) {
                final date = timeSlotsByDay.keys.elementAt(dayIndex);
                final slots = timeSlotsByDay[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        DateFormat('dd MMMM', 'ru').format(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final time = slots[index];
                        final fullDateTime =
                            '${DateFormat('yyyy-MM-dd').format(date)} $time';
                        final isSelected = fullDateTime == selectedStartTime ||
                            fullDateTime == selectedEndTime;
                        final isAvailable = _isTimeSlotAvailable(date, time);

                        return GestureDetector(
                          onTap: isAvailable
                              ? () => _selectTime(time, date)
                              : null,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isAvailable
                                      ? Colors.grey[200]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 22,
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                        ? AppColors.primary
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Bottom info section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Стоимость:',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      calculatedTotal != null
                          ? '$calculatedTotal ₸'
                          : 'Укажите время',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Дата начала:',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatSelectedDateTime(selectedStartTime),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Дата окончания:',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatSelectedDateTime(selectedEndTime),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedStartTime != null && selectedEndTime != null)
                  CustomButton(
                    onPressed: _onConfirm,
                    isFullWidth: true,
                    label: 'Подтвердить',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
