import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:intl/intl.dart';

class TicketsPage extends ConsumerWidget {
  final int mallId;

  const TicketsPage({
    super.key,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.appBg,
                margin: const EdgeInsets.only(top: 64),
                child: ticketsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                  data: (tickets) {
                    if (tickets.isEmpty) {
                      return const Center(
                        child: Text('У вас пока нет купонов'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.promotionName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (ticket.receiptNo != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Чек №${ticket.receiptNo}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                              if (ticket.amount != null) ...[
                                Text(
                                  'Сумма чека: ${ticket.amount?.toStringAsFixed(0)} ₸',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                              if (ticket.organization != null) ...[
                                Text(
                                  'Организация: ${ticket.organization}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                              if (ticket.purchaseDate != null) ...[
                                Text(
                                  'Дата покупки: ${DateFormat('dd.MM.yy').format(ticket.purchaseDate!)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                              Text(
                                'Дата регистрации чека: ${DateFormat('dd.MM.yy').format(ticket.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const CustomHeader(
                title: "Купоны",
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
