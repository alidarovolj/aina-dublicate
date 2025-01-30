import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    super.key,
    required this.orderData,
  });

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  Timer? _timer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final createdAt = DateTime.parse(widget.orderData['created_at']);
    final endTime = createdAt.add(const Duration(minutes: 15));

    void updateTimer() {
      final now = DateTime.now();
      if (now.isBefore(endTime)) {
        final remaining = endTime.difference(now);
        setState(() {
          _remainingTime =
              '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      } else {
        _timer?.cancel();
        setState(() {
          _remainingTime = '00:00';
        });
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
    updateTimer();
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    final date = DateTime.parse(dateTime);
    return DateFormat('dd.MM.yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userData = authState.userData;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Заказ №${widget.orderData['id']}',
              type: HeaderType.pop,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (widget.orderData['status'] == 'PENDING' &&
                            _remainingTime.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Ожидает оплаты $_remainingTime',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildInfoRow(
                            'Профиль:', userData?['phone']?['masked'] ?? ''),
                        _buildInfoRow(
                            'Услуга:',
                            widget.orderData['service']?['category']
                                    ?['title'] ??
                                ''),
                        _buildInfoRow('Название:',
                            widget.orderData['service']?['title'] ?? ''),
                        _buildInfoRow('Дата начала:',
                            _formatDateTime(widget.orderData['start_at'])),
                        _buildInfoRow('Дата окончания:',
                            _formatDateTime(widget.orderData['end_at'])),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Итоговая стоимость:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${widget.orderData['total']} ₸',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Оплачивая, вы подтверждаете что, ознакомились и согласны с правилами пользования конференц-залами и коворкингом',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.orderData['status'] == 'PENDING')
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement payment
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Оплатить'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
