import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:shimmer/shimmer.dart';

class TicketsPage extends ConsumerStatefulWidget {
  final bool? isFromQr;

  const TicketsPage({
    super.key,
    this.isFromQr,
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

  Widget _buildUnauthorizedState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'tickets.auth_required'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            label: 'tickets.authorize'.tr(),
            type: ButtonType.filled,
            isFullWidth: true,
            onPressed: () {
              context.push('/login');
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTicketSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (widget.isFromQr == true) {
      context.go('/home');
    } else {
      context.pop();
    }
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
                color: Colors.white,
                margin: const EdgeInsets.only(top: 64),
                child: ticketsAsync.when(
                  loading: () => _buildTicketSkeleton(),
                  error: (error, stack) {
                    if (error.toString().contains('401')) {
                      return _buildUnauthorizedState();
                    }
                    return Center(
                      child: Text('tickets.error'.tr(args: [error.toString()])),
                    );
                  },
                  data: (tickets) {
                    if (tickets.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'tickets.no_tickets'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                onBack: () => _handleBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
