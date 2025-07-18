import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:aina_flutter/features/coworking/model/models/coworking_tariff_details.dart';
import 'package:aina_flutter/features/coworking/model/providers/coworking_tariff_details_provider.dart';
import 'package:aina_flutter/features/coworking/ui/pages/widgets/time_selection_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/features/coworking/model/models/order_request.dart';
import 'package:aina_flutter/features/coworking/model/services/order_service.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:shimmer/shimmer.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

class CoworkingCalendarPage extends ConsumerStatefulWidget {
  final int tariffId;

  const CoworkingCalendarPage({
    super.key,
    required this.tariffId,
  });

  @override
  ConsumerState<CoworkingCalendarPage> createState() =>
      _CoworkingCalendarPageState();
}

class _CoworkingCalendarPageState extends ConsumerState<CoworkingCalendarPage> {
  DateTime? selectedDate;
  DateTime? endDate;
  int? total;
  final today = DateTime.now();
  final yearsToShow = 3;
  late final ScrollController _scrollController;
  late List<DateTime> months;
  List<ReservedDateRange> reservedDates = [];
  bool isLoading = true;

  // Form data
  late Map<String, dynamic> formData = {
    'start_at': '',
    'end_at': '',
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Generate initial months for the first year
    months = List.generate(
      12,
      (i) => DateTime(today.year, today.month + i, 1),
    ).where((date) {
      // Filter out months that are beyond yearsToShow
      final maxDate = DateTime(today.year + yearsToShow, today.month, 1);
      return !date.isAfter(maxDate);
    }).toList();

    // Add scroll listener for loading more months
    _scrollController.addListener(_onScroll);

    // Schedule initialization after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreMonths();
    }
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First, load tariff details
      await ref
          .read(coworkingTariffDetailsProvider.notifier)
          .fetchTariffDetails(widget.tariffId);

      // Then, load reserved dates
      await _loadReservedDates();
    } catch (e) {
      // Error handling without print
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReservedDates() async {
    try {
      final tariffDetails = ref.read(coworkingTariffDetailsProvider).value;
      if (tariffDetails == null) {
        return;
      }

      // Skip loading reserved dates if not a COWORKING type tariff
      if (tariffDetails.type != 'COWORKING') {
        setState(() {
          reservedDates = [];
        });
        return;
      }

      final apiClient = ref.read(apiClientProvider);
      List<ReservedDateRange> allReservedDates = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        final response = await apiClient.dio.get(
          '/api/promenade/orders',
          queryParameters: {
            'state_group': 'ACTIVE',
            'per_page': 100,
            'page': currentPage,
          },
          options: Options(
            headers: {
              'force-refresh': 'true',
            },
          ),
        );

        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true &&
            response.data['data'] != null) {
          final List<dynamic> ordersData =
              response.data['data'] as List<dynamic>;

          final List<ReservedDateRange> pageReservedDates = ordersData
              .map((order) {
                try {
                  if (order is Map<String, dynamic> &&
                      order['start_at'] != null &&
                      order['end_at'] != null) {
                    return ReservedDateRange(
                      startAt: order['start_at'].toString(),
                      endAt: order['end_at'].toString(),
                      orderData: order,
                    );
                  }
                } catch (e) {
                  // Error handling without print
                }
                return null;
              })
              .whereType<ReservedDateRange>()
              .toList();

          allReservedDates.addAll(pageReservedDates);

          // Check if we have more pages
          final meta = response.data['meta'] as Map<String, dynamic>?;
          if (meta != null) {
            final lastPage = meta['last_page'] as int? ?? 1;
            hasMorePages = currentPage < lastPage;
            currentPage++;
          } else {
            hasMorePages = false;
          }
        } else {
          hasMorePages = false;
        }
      }

      if (mounted) {
        setState(() {
          reservedDates = allReservedDates;
        });
      }
    } catch (e) {
      // Error handling without print
    }
  }

  List<DateTime?> _daysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // Calculate empty days at start (Monday = 1, Sunday = 7)
    final firstWeekday = firstDay.weekday;
    final daysBeforeMonth = firstWeekday - 1;

    // Calculate days in month
    final daysInMonth = lastDay.day;

    // Calculate empty days at end
    final lastWeekday = lastDay.weekday;
    final daysAfterMonth = 7 - lastWeekday;

    // Generate the full list of days
    final days = List<DateTime?>.filled(
        daysBeforeMonth + daysInMonth + daysAfterMonth, null);

    // Fill in the actual days
    for (var i = 0; i < daysInMonth; i++) {
      days[daysBeforeMonth + i] = DateTime(month.year, month.month, i + 1);
    }

    return days;
  }

  bool _isAvailableDay(DateTime date) {
    final tariffDetails = ref.read(coworkingTariffDetailsProvider).value;
    if (tariffDetails == null) return false;

    // Block past days
    if (date.isBefore(DateTime(today.year, today.month, today.day))) {
      return false;
    }

    // Block dates beyond yearsToShow
    final maxDate = DateTime(today.year + yearsToShow, today.month, today.day);
    if (date.isAfter(maxDate)) {
      return false;
    }

    try {
      final timeUnit = (tariffDetails.timeUnit ?? 'day').toLowerCase();
      final startDay = (tariffDetails.startDay ?? 'ANY_DAY').toUpperCase();

      // If start_day is ANY_DAY, all future days are available
      if (startDay == 'ANY_DAY') {
        return true;
      }

      // For specific start days (like MONDAY for week tariffs)
      final weekdayMap = {
        'MONDAY': DateTime.monday,
        'TUESDAY': DateTime.tuesday,
        'WEDNESDAY': DateTime.wednesday,
        'THURSDAY': DateTime.thursday,
        'FRIDAY': DateTime.friday,
        'SATURDAY': DateTime.saturday,
        'SUNDAY': DateTime.sunday,
      };

      if (weekdayMap.containsKey(startDay)) {
        return date.weekday == weekdayMap[startDay];
      }

      return true;
    } catch (e) {
      // Error handling without print
      return false;
    }
  }

  bool _isInRange(DateTime date) {
    if (selectedDate == null || endDate == null) return false;

    // Include both start and end dates in the range
    final start =
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    final current = DateTime(date.year, date.month, date.day);

    return !current.isBefore(start) && !current.isAfter(end);
  }

  bool _isRangeOverlappingReserved(DateTime start, DateTime end) {
    // Normalize dates to start of day for consistent comparison
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day);

    return reservedDates.any((range) {
      // Проверяем тип сервиса в заказе
      final orderData = range.orderData;
      if (orderData == null || orderData['service']?['type'] != 'COWORKING') {
        return false;
      }

      final reservedStart = DateTime.parse(range.startAt).toLocal();
      final reservedEnd = DateTime.parse(range.endAt).toLocal();

      // Normalize reserved dates to start of day
      final normalizedReservedStart = DateTime(
        reservedStart.year,
        reservedStart.month,
        reservedStart.day,
      );
      final normalizedReservedEnd = DateTime(
        reservedEnd.year,
        reservedEnd.month,
        reservedEnd.day,
      );

      // Check if any day in the range overlaps with reserved dates
      for (var day = rangeStart;
          !day.isAfter(rangeEnd);
          day = day.add(const Duration(days: 1))) {
        if (!day.isBefore(normalizedReservedStart) &&
            !day.isAfter(normalizedReservedEnd)) {
          return true;
        }
      }
      return false;
    });
  }

  void _selectDate(DateTime date) {
    if (!_isAvailableDay(date)) return;

    final tariffDetails = ref.read(coworkingTariffDetailsProvider).value;
    if (tariffDetails == null) return;

    try {
      // Check if the selected date itself is reserved
      if (_isDateReserved(date)) {
        _showReservedDateModal(context);
        return;
      }

      // Calculate end date based on duration and time unit
      final calculatedEndDate = _calculateEndDate(date, tariffDetails);

      // Check for overlap with reserved dates in the entire range
      if (_isRangeOverlappingReserved(date, calculatedEndDate)) {
        _showReserveOverlapModal(context);
        return;
      }

      // Для почасовой брони показываем модальное окно выбора времени
      if ((tariffDetails.timeUnit ?? 'day').toLowerCase() == 'hour') {
        _showTimeSelectionModal(context, date, tariffDetails);
        return;
      }

      setState(() {
        selectedDate = date;
        endDate = calculatedEndDate;
        final startTimeAt = tariffDetails.startTimeAt != null &&
                tariffDetails.startTimeAt!.isNotEmpty
            ? tariffDetails.startTimeAt!
            : '00:00:00';
        final rawEndTimeAt = tariffDetails.endTimeAt != null &&
                tariffDetails.endTimeAt!.isNotEmpty
            ? tariffDetails.endTimeAt!
            : '23:59:59';

        // Parse end time and subtract one second
        final endTimeParts = rawEndTimeAt.split(':');
        final endHour = int.parse(endTimeParts[0]);
        final endMinute = int.parse(endTimeParts[1]);
        final endSecond = int.parse(endTimeParts[2]);

        final adjustedEndTime = DateTime(
          calculatedEndDate.year,
          calculatedEndDate.month,
          calculatedEndDate.day,
          endHour,
          endMinute,
          endSecond,
        ).subtract(const Duration(seconds: 1));

        final endTimeAt = DateFormat('HH:mm:ss').format(adjustedEndTime);

        // Set the form values with proper time formatting
        formData['start_at'] =
            '${DateFormat('yyyy-MM-dd').format(date)} $startTimeAt';
        formData['end_at'] =
            '${DateFormat('yyyy-MM-dd').format(calculatedEndDate)} $endTimeAt';
        total = tariffDetails.price;
      });
    } catch (e) {
      // Error handling without print
    }
  }

  DateTime _calculateEndDate(
      DateTime startDate, CoworkingTariffDetails tariffDetails) {
    final timeUnit = (tariffDetails.timeUnit ?? 'day').toLowerCase();
    final duration = tariffDetails.duration ?? 1;

    DateTime endDate;
    switch (timeUnit) {
      case 'hour':
        // Для почасовой брони оставляем тот же день
        endDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        break;
      case 'day':
        endDate = startDate.add(Duration(days: duration - 1));
        break;
      case 'week':
        endDate = startDate.add(Duration(days: (duration * 7) - 1));
        break;
      case 'month':
        // Add months by calculating the target month and year
        int targetMonth = startDate.month + duration;
        int targetYear = startDate.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        // Subtract one day to get the end of the previous month
        endDate = DateTime(targetYear, targetMonth, startDate.day)
            .subtract(const Duration(days: 1));
        break;
      case 'year':
        // Для годовой подписки добавляем указанное количество лет и вычитаем один день
        endDate = DateTime(
          startDate.year + duration,
          startDate.month,
          startDate.day,
        ).subtract(const Duration(days: 1));
        break;
      default:
        endDate = startDate;
    }

    // Возвращаем только дату без установки времени, так как время будет взято из тарифа
    return DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );
  }

  bool _isDateReserved(DateTime date) {
    final current = DateTime(date.year, date.month, date.day);

    return reservedDates.any((range) {
      // Проверяем тип сервиса в заказе
      final orderData = range.orderData;
      if (orderData == null || orderData['service']?['type'] != 'COWORKING') {
        return false;
      }

      final startDate = DateTime.parse(range.startAt).toLocal();
      final endDate = DateTime.parse(range.endAt).toLocal();
      final rangeStart =
          DateTime(startDate.year, startDate.month, startDate.day);
      final rangeEnd = DateTime(endDate.year, endDate.month, endDate.day);

      return !current.isBefore(rangeStart) && !current.isAfter(rangeEnd);
    });
  }

  Widget _buildMonthGrid(DateTime month) {
    final days = _daysInMonth(month);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) return const SizedBox.shrink();

        return _buildDayCell(day);
      },
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isAvailable = _isAvailableDay(day);
    final isSelected = selectedDate?.year == day.year &&
        selectedDate?.month == day.month &&
        selectedDate?.day == day.day;
    final isInRange = _isInRange(day);
    final isReserved = _isDateReserved(day);

    // Don't allow selection or range display for reserved dates
    final showSelected = (isSelected || isInRange) && !isReserved;

    return GestureDetector(
      onTap: isAvailable && !isReserved ? () => _selectDate(day) : null,
      child: Container(
        decoration: BoxDecoration(
          color: showSelected ? AppColors.primary : Colors.white,
          border: isReserved
              ? Border.all(
                  color: const Color(0xFFE6B012),
                  width: 1,
                )
              : Border.all(
                  color: Colors.grey.withAlpha(51),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w400,
              color: showSelected
                  ? Colors.white
                  : !isAvailable || isReserved
                      ? Colors.grey.withAlpha(128)
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                DateFormat('MMMM yyyy', 'ru').format(month).toLowerCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: const [
                'coworking.calendar.weekdays.mon',
                'coworking.calendar.weekdays.tue',
                'coworking.calendar.weekdays.wed',
                'coworking.calendar.weekdays.thu',
                'coworking.calendar.weekdays.fri',
                'coworking.calendar.weekdays.sat',
                'coworking.calendar.weekdays.sun'
              ]
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day.tr(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            _buildMonthGrid(month),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _loadMoreMonths() {
    if (months.length >= yearsToShow * 12) return; // Limit to yearsToShow years

    final lastMonth = months.last;
    final nextMonths = List.generate(
      12,
      (i) => DateTime(lastMonth.year, lastMonth.month + i + 1, 1),
    );

    setState(() {
      months.addAll(nextMonths);
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? date, String? time) {
    if (date == null) return 'Не выбрано';
    final dateStr = DateFormat('dd.MM.yyyy').format(date);
    final timeStr = time ?? '00:00:00';
    return '$dateStr $timeStr';
  }

  void _showReservedDateModal(BuildContext context) {
    BaseModal.show(
      context,
      message: 'coworking.calendar.reserved_date'.tr(),
      buttons: [
        ModalButton(
          label: 'coworking.calendar.go_back'.tr(),
          onPressed: () {},
          type: ButtonType.normal,
          backgroundColor: AppColors.lightGrey,
          textColor: AppColors.textDarkGrey,
        ),
      ],
    );
  }

  void _showReservedInfoModal(BuildContext context) {
    BaseModal.show(
      context,
      message: 'coworking.calendar.reserved_info'.tr(),
      buttons: [
        ModalButton(
          label: 'coworking.calendar.go_back'.tr(),
          onPressed: () {},
          type: ButtonType.normal,
          backgroundColor: AppColors.lightGrey,
          textColor: AppColors.textDarkGrey,
        ),
      ],
    );
  }

  void _showReserveOverlapModal(BuildContext context) {
    BaseModal.show(
      context,
      message: 'coworking.calendar.overlap_error'.tr(),
      buttons: [
        ModalButton(
          label: 'coworking.calendar.go_back'.tr(),
          onPressed: () {},
          type: ButtonType.normal,
          backgroundColor: AppColors.lightGrey,
          textColor: AppColors.textDarkGrey,
        ),
      ],
    );
  }

  void _showTimeSelectionModal(BuildContext context, DateTime date,
      CoworkingTariffDetails tariffDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TimeSelectionModal(
        date: date,
        tariffDetails: tariffDetails,
        onTimeSelected: (startTime, endTime, total) {
          setState(() {
            selectedDate = date;
            endDate = date; // Для почасовой брони конечная дата та же
            formData['start_at'] = startTime;
            formData['end_at'] = endTime;
            this.total = total;
          });
        },
      ),
    );
  }

  Future<void> _handlePaymentPress() async {
    if (selectedDate == null || endDate == null) {
      BaseSnackBar.show(
        context,
        message: 'coworking.calendar.select_date'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final orderRequest = OrderRequest(
        startAt: formData['start_at'],
        endAt: formData['end_at'],
        serviceId: widget.tariffId,
      );

      final order = await orderService.createOrder(orderRequest);

      setState(() => isLoading = false);

      if (!mounted) return;

      context.pushNamed(
        'order_details',
        pathParameters: {
          'id': order.id.toString(),
        },
        extra: {
          'referrer': 'calendar',
          'isFromCalendar': true,
        },
      );
    } catch (e) {
      // Error handling without print
      setState(() => isLoading = false);
      if (!mounted) return;

      BaseSnackBar.show(
        context,
        message: 'coworking.calendar.order_error'.tr(),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariffDetailsState = ref.watch(coworkingTariffDetailsProvider);

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              _loadReservedDates();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                if (isLoading)
                  _buildSkeletonLoader()
                else
                  tariffDetailsState.when(
                    data: (tariffDetails) {
                      if (tariffDetails == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Тариф не найден',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                label: 'Вернуться назад',
                                onPressed: () => context.pop(),
                                isFullWidth: false,
                              ),
                            ],
                          ),
                        );
                      }
                      return Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            const SizedBox(height: 64),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'coworking.calendar.select_date'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ).tr(),
                                  IconButton(
                                    onPressed: () =>
                                        _showReservedInfoModal(context),
                                    icon: const Icon(Icons.info_outline,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildCalendar()),
                            if (selectedDate !=
                                null) // Only show when date is selected
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(26),
                                      blurRadius: 10,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                        '${'coworking.calendar.cost'.tr()}:',
                                        '${total ?? tariffDetails.price} ₸'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      '${'coworking.calendar.start_date'.tr()}:',
                                      formData['start_at'].isNotEmpty
                                          ? DateFormat('dd.MM.yyyy HH:mm:ss')
                                              .format(DateTime.parse(
                                                  formData['start_at']))
                                          : 'coworking.calendar.not_selected'
                                              .tr(),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      '${'coworking.calendar.end_date'.tr()}:',
                                      formData['end_at'].isNotEmpty
                                          ? DateFormat('dd.MM.yyyy HH:mm:ss')
                                              .format(DateTime.parse(
                                                  formData['end_at']))
                                          : 'coworking.calendar.not_selected'
                                              .tr(),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomButton(
                                      label:
                                          'coworking.calendar.proceed_to_payment'
                                              .tr(),
                                      onPressed: isLoading
                                          ? null
                                          : _handlePaymentPress,
                                      isFullWidth: true,
                                      isLoading: isLoading,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => _buildSkeletonLoader(),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ошибка: $error',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'Вернуться назад',
                            onPressed: () => context.pop(),
                            isFullWidth: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                CustomHeader(
                  title: tariffDetailsState.whenOrNull(
                        data: (tariffDetails) =>
                            tariffDetails?.title ??
                            'coworking.calendar.page_title'.tr(),
                      ) ??
                      'coworking.calendar.page_title'.tr(),
                  type: HeaderType.pop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        const SizedBox(height: 64),
        // Calendar title and info button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Calendar grid
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 3, // Show 3 months
            itemBuilder: (context, monthIndex) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Weekday headers
                  Row(
                    children: List.generate(
                      7,
                      (index) => Expanded(
                        child: Center(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[100]!,
                            highlightColor: Colors.grey[300]!,
                            child: Container(
                              width: 20,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Calendar days grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 42, // 6 weeks * 7 days
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[100]!,
                        highlightColor: Colors.grey[300]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
        // Bottom info panel
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cost row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Start date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // End date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Payment button
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReservedDateRange {
  final String startAt;
  final String endAt;
  final Map<String, dynamic>? orderData;

  ReservedDateRange({
    required this.startAt,
    required this.endAt,
    this.orderData,
  });

  @override
  String toString() => 'ReservedDateRange(startAt: $startAt, endAt: $endAt)';
}
