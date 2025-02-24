import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_tariff_details.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/features/coworking/domain/services/order_service.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/calendar_response.dart';

class TimeSelectionModal extends StatefulWidget {
  final DateTime date;
  final CoworkingTariffDetails tariffDetails;
  final Function(String startTime, String endTime, int total)? onTimeSelected;
  final bool isConference;

  const TimeSelectionModal({
    super.key,
    required this.date,
    required this.tariffDetails,
    this.onTimeSelected,
    this.isConference = false,
  });

  @override
  State<TimeSelectionModal> createState() => _TimeSelectionModalState();
}

class _TimeSelectionModalState extends State<TimeSelectionModal> {
  String? selectedStartTime;
  String? selectedEndTime;
  bool selectingStartTime = true;
  Map<DateTime, List<String>> timeSlotsByDay = {};
  int? calculatedTotal;
  List<TimeRange> busyTimeRanges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await OrderService(ApiClient()).getCalendar(
        DateFormat('yyyy-MM-dd').format(widget.date),
        widget.tariffDetails.id.toString(),
      );
      setState(() {
        busyTimeRanges = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      // Handle error
    }
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

  bool _isTimeSlotSelectable(DateTime date, String time) {
    if (!_isTimeSlotAvailable(date, time)) {
      return false;
    }

    final slotDateTime =
        DateTime.parse('${DateFormat('yyyy-MM-dd').format(date)} $time:00');

    // Если выбираем начальное время
    if (selectingStartTime) {
      // Проверяем, не попадает ли время в занятый промежуток
      for (final range in busyTimeRanges) {
        final rangeStart = DateTime.parse(range.startAt).toLocal();
        final rangeEnd = DateTime.parse(range.endAt).toLocal();
        if (slotDateTime.isAtSameMomentAs(rangeStart) ||
            (slotDateTime.isAfter(rangeStart) &&
                slotDateTime.isBefore(rangeEnd))) {
          return false;
        }
      }
      return true;
    }
    // Если выбираем конечное время
    else if (selectedStartTime != null) {
      final startDateTime = DateTime.parse(
          '${DateFormat('yyyy-MM-dd').format(date)} ${selectedStartTime!.split(' ')[1]}:00');
      final minDuration = widget.tariffDetails.minDuration ?? 2;
      final difference = slotDateTime.difference(startDateTime).inHours;

      // Проверяем минимальную длительность
      if (difference < minDuration) {
        return false;
      }

      // Проверяем пересечение с занятыми промежутками
      for (final range in busyTimeRanges) {
        final rangeStart = DateTime.parse(range.startAt).toLocal();
        final rangeEnd = DateTime.parse(range.endAt).toLocal();

        // Проверяем, не пересекается ли выбранный промежуток с занятым
        if (startDateTime.isBefore(rangeStart) &&
            slotDateTime.isAfter(rangeEnd)) {
          continue; // Если наш интервал полностью охватывает занятый - это недопустимо
        }

        if (startDateTime.isAfter(rangeEnd) ||
            slotDateTime.isBefore(rangeStart)) {
          continue; // Если наш интервал полностью до или после занятого - это допустимо
        }

        return false; // В остальных случаях есть пересечение
      }
      return true;
    }

    return false;
  }

  void _selectTime(String time, DateTime date) {
    if (selectingStartTime) {
      final fullDateTime =
          '${DateFormat('yyyy-MM-dd').format(date)} ${time.substring(0, 5)}';
      if (fullDateTime == selectedStartTime) {
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
      final fullDateTime =
          '${DateFormat('yyyy-MM-dd').format(date)} ${time.substring(0, 5)}';
      final start = DateTime.parse('$selectedStartTime:00');
      final end = DateTime.parse('$fullDateTime:00');

      final minDuration = widget.tariffDetails.minDuration ?? 2;
      final difference = end.difference(start).inHours;

      if (difference < minDuration) {
        return;
      }

      // Проверяем пересечение с занятыми промежутками
      bool hasIntersection = false;
      for (final range in busyTimeRanges) {
        final rangeStart = DateTime.parse(range.startAt).toLocal();
        final rangeEnd = DateTime.parse(range.endAt).toLocal();

        if (start.isBefore(rangeStart) && end.isAfter(rangeEnd)) {
          hasIntersection = true;
          break;
        }

        if (start.isAfter(rangeEnd) || end.isBefore(rangeStart)) {
          continue;
        }

        hasIntersection = true;
        break;
      }

      if (hasIntersection) {
        setState(() {
          selectedStartTime = null;
          selectedEndTime = null;
          calculatedTotal = null;
          selectingStartTime = true;
        });

        BaseModal.show(
          context,
          title: 'coworking.time_selection.error.title'.tr(),
          message: 'coworking.time_selection.error.intersection'.tr(),
          buttons: [
            ModalButton(
              label: 'coworking.time_selection.error.back'.tr(),
              onPressed: () {},
              type: ButtonType.normal,
            ),
          ],
        );
        return;
      }

      if (fullDateTime == selectedEndTime) {
        setState(() {
          selectedEndTime = null;
          calculatedTotal = null;
          selectingStartTime = true;
        });
        return;
      }

      setState(() {
        selectedEndTime = fullDateTime;
        isLoading = true;
      });

      // Make pre-calculation request
      OrderService(ApiClient())
          .preCalculateOrder(
        serviceId: widget.tariffDetails.id,
        startAt: '$selectedStartTime:00',
        endAt: '$fullDateTime:00',
      )
          .then((response) {
        setState(() {
          calculatedTotal = response.total;
          selectingStartTime = true;
          isLoading = false;
        });

        widget.onTimeSelected?.call(
          selectedStartTime!,
          selectedEndTime!,
          calculatedTotal ?? 0,
        );
      }).catchError((error) {
        print('Error in pre-calculation: $error');
        setState(() {
          selectedEndTime = null;
          calculatedTotal = null;
          selectingStartTime = true;
          isLoading = false;
        });

        BaseModal.show(
          context,
          title: 'coworking.time_selection.error.title'.tr(),
          message: 'coworking.time_selection.error.calculation'.tr(),
          buttons: [
            ModalButton(
              label: 'coworking.time_selection.error.back'.tr(),
              onPressed: () {},
              type: ButtonType.normal,
            ),
          ],
        );
      });
    }
  }

  String _formatSelectedDateTime(String? fullDateTime) {
    if (fullDateTime == null) {
      return 'coworking.time_selection.not_selected'.tr();
    }
    final dateTime = DateTime.parse('$fullDateTime:00');
    return DateFormat('dd:MM:yyyy HH:mm').format(dateTime);
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
            'startTime': selectedStartTime!,
            'endTime': selectedEndTime!,
          },
        );
      } else {
        widget.onTimeSelected?.call(
          selectedStartTime!,
          selectedEndTime!,
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
                  'coworking.time_selection.title'.tr(
                    args: [(widget.tariffDetails.minDuration ?? 2).toString()],
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                            Text(
                              'coworking.time_selection.start'.tr(),
                              style: const TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedStartTime != null &&
                                selectedEndTime != null)
                              Text(
                                _formatSelectedDateTime(selectedStartTime),
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
                            Text(
                              'coworking.time_selection.end'.tr(),
                              style: const TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedStartTime != null &&
                                selectedEndTime != null)
                              Text(
                                _formatSelectedDateTime(selectedEndTime),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: timeSlotsByDay.length,
              itemBuilder: (context, dayIndex) {
                final date = timeSlotsByDay.keys.elementAt(dayIndex);
                final slots = timeSlotsByDay[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: Text(
                        DateFormat('dd MMMM', context.locale.languageCode)
                            .format(date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 6,
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
                        final isSelectable = _isTimeSlotSelectable(date, time);

                        // Check if this time slot is in the selected range
                        bool isInRange = false;
                        if (selectedStartTime != null &&
                            selectedEndTime != null) {
                          final currentDateTime =
                              DateTime.parse('$fullDateTime:00');
                          final startDateTime =
                              DateTime.parse('$selectedStartTime:00');
                          final endDateTime =
                              DateTime.parse('$selectedEndTime:00');
                          isInRange = currentDateTime.isAfter(startDateTime) &&
                              currentDateTime.isBefore(endDateTime);
                        }

                        return GestureDetector(
                          onTap: isSelectable
                              ? () => _selectTime(time, date)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isInRange
                                      ? AppColors.primary.withOpacity(0.3)
                                      : isSelectable
                                          ? AppColors.lightGrey
                                          : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected || isInRange
                                    ? Colors.white
                                    : isSelectable
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
                      'coworking.time_selection.cost'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      calculatedTotal != null
                          ? '$calculatedTotal ₸'
                          : 'coworking.time_selection.specify_time'.tr(),
                      style: const TextStyle(
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
                      'coworking.time_selection.start_date'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatSelectedDateTime(selectedStartTime),
                      style: const TextStyle(
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
                      'coworking.time_selection.end_date'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatSelectedDateTime(selectedEndTime),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: _onConfirm,
                  isFullWidth: true,
                  isEnabled:
                      selectedStartTime != null && selectedEndTime != null,
                  label: 'coworking.time_selection.confirm'.tr(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
