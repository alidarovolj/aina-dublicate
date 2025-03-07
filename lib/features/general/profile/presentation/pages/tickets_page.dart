import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:easy_localization/easy_localization.dart';

class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({
    super.key,
  });

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userTicketsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text('tickets.error'.tr(args: [error.toString()])),
                  ),
                  data: (tickets) {
                    if (tickets.isEmpty) {
                      return Center(
                        child: Text('tickets.no_tickets'.tr()),
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
                            color: ticket.promotionType == 'RAFFLE'
                                ? null
                                : Colors.white,
                            gradient: ticket.promotionType == 'RAFFLE'
                                ? const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color.fromARGB(255, 186, 167, 82),
                                      Color.fromARGB(255, 224, 206, 117),
                                    ],
                                  )
                                : null,
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
                              if (ticket.promotionName != null) ...[
                                Text(
                                  ticket.promotionName!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ticket.promotionType == 'RAFFLE'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (ticket.receiptNo != null) ...[
                                Text(
                                  'tickets.receipt_number'
                                      .tr(args: [ticket.receiptNo!]),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ticket.promotionType == 'RAFFLE'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                              if (ticket.amount != null) ...[
                                Text(
                                  'tickets.receipt_amount'.tr(args: [
                                    ticket.amount!.toStringAsFixed(0)
                                  ]),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ticket.promotionType == 'RAFFLE'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                              if (ticket.organization != null) ...[
                                Text(
                                  'tickets.organization'
                                      .tr(args: [ticket.organization!]),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ticket.promotionType == 'RAFFLE'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                              Text(
                                'Купон №${ticket.ticketNo}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ticket.promotionType == 'RAFFLE'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                'tickets.registration_date'.tr(args: [
                                  DateFormat('dd.MM.yy')
                                      .format(ticket.createdAt)
                                ]),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ticket.promotionType == 'RAFFLE'
                                      ? Colors.white
                                      : Colors.black,
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
              CustomHeader(
                title: 'tickets.title'.tr(),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
