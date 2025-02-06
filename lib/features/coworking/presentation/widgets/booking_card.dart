import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';

class BookingCard extends StatefulWidget {
  final OrderResponse order;
  final Function(int)? onTimerExpired;

  const BookingCard({
    Key? key,
    required this.order,
    this.onTimerExpired,
  }) : super(key: key);

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  Timer? _timer;
  String? _timerDisplay;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == 'PENDING') {
      _calculateRemainingTime();
    }
  }

  void _calculateRemainingTime() {
    final createdAt =
        DateTime.parse(widget.order.createdAt).millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final fifteenMinutes = 15 * 60 * 1000; // 15 minutes in milliseconds
    final endTime = createdAt + fifteenMinutes;
    _remainingTime = ((endTime - now) / 1000).floor();

    if (_remainingTime > 0) {
      _startTimer();
    } else {
      _timerDisplay = "00:00";
      widget.onTimerExpired?.call(widget.order.id);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          final minutes = (_remainingTime ~/ 60).toString().padLeft(2, '0');
          final seconds = (_remainingTime % 60).toString().padLeft(2, '0');
          _timerDisplay = "$minutes:$seconds";
        });
      } else {
        timer.cancel();
        _timerDisplay = "00:00";
        widget.onTimerExpired?.call(widget.order.id);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case 'PAID':
        return const Color(0xFF2AC52A);
      case 'PENDING':
        return const Color(0xFFD42525);
      case 'CANCELED':
      case 'REFUND':
        return const Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.order.status) {
      case 'PAID':
        return 'orders.status.paid'.tr();
      case 'PENDING':
        return 'orders.status.pending'.tr();
      case 'CANCELED':
        return 'orders.status.cancelled'.tr();
      case 'REFUND':
        return 'orders.status.refunded'.tr();
      default:
        return widget.order.status;
    }
  }

  String _getImageUrl() {
    final service = widget.order.service;
    final serviceImage = service?.image;
    final categoryImage = service?.category?.image;

    if (categoryImage?.url != null) {
      return categoryImage!.url;
    }
    if (serviceImage?.url != null) {
      return serviceImage!.url;
    }
    return 'https://placeholder.com/64x64';
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.order.service;
    final categoryTitle = service?.category?.title;
    final serviceTitle = service?.title ?? '';

    return GestureDetector(
      onTap: () => context.push('/orders/${widget.order.id}',
          extra: widget.order.toJson()),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // light-grey
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStatusColor(),
                    ),
                  ),
                  if (widget.order.status == 'PENDING' &&
                      _timerDisplay != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      _timerDisplay!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor().withOpacity(0.1),
                    ),
                    child: Icon(
                      widget.order.status == 'PAID'
                          ? Icons.check_circle
                          : Icons.error,
                      size: 16,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Order Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    _getImageUrl(),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryTitle != null)
                        Text(
                          categoryTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A), // almost-black
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        serviceTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666), // text-dark-grey
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF666666),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('HH:mm').format(DateTime.parse(widget.order.startAt))} - '
                                '${DateFormat('HH:mm').format(DateTime.parse(widget.order.endAt))}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${NumberFormat('#,###', 'ru-RU').format(widget.order.total)} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4D4D4D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
