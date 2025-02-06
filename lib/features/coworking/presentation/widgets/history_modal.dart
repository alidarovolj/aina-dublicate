import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';

class HistoryModal extends StatelessWidget {
  final List<OrderHistory> history;

  const HistoryModal({
    super.key,
    required this.history,
  });

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reversedHistory = history.reversed.toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История заказа',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(reversedHistory.length, (index) {
                    final item = reversedHistory[index];
                    return Stack(
                      children: [
                        if (index < reversedHistory.length - 1)
                          Positioned(
                            left: 3.5,
                            top: 14,
                            bottom: -30,
                            child: Container(
                              width: 1,
                              color: const Color(0xFFE6E6E6),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.only(top: 6, right: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4B33E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(item.actionAt),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Назад к заказу',
              onPressed: () => Navigator.of(context).pop(),
              isFullWidth: true,
              type: ButtonType.normal,
              backgroundColor: const Color(0xFFE6E6E6),
              textColor: const Color(0xFF1A1A1A),
            ),
          ],
        ),
      ),
    );
  }
}

void showHistoryModal(BuildContext context, List<OrderHistory> history) {
  showDialog(
    context: context,
    builder: (context) => HistoryModal(history: history),
  );
}
