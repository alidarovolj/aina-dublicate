import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/domain/providers/quota_provider.dart';
import 'package:aina_flutter/features/coworking/domain/models/quota.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class LimitAccountsPage extends ConsumerWidget {
  final int coworkingId;

  const LimitAccountsPage({
    super.key,
    required this.coworkingId,
  });

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotasAsync = ref.watch(quotasProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                margin: const EdgeInsets.only(top: 64),
                child: quotasAsync.when(
                  data: (quotas) => _buildSettingsList(context, quotas),
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
              CustomHeader(
                title: tr('limits.title'),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, List<Quota> quotas) {
    if (quotas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr('limits.no_quotas'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDarkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  context.push('/coworking/$coworkingId/profile');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('coworking.profile.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quotas.length,
      itemBuilder: (context, index) {
        final quota = quotas[index];
        return _QuotaCard(
          quota: quota,
          onTap: () {
            context.push('/orders/${quota.id}');
          },
          formatDate: formatDate,
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status section skeleton
                  Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Content section skeleton
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image placeholder skeleton
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title skeleton
                            Container(
                              width: 150,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 13),
                            // Remaining and free status skeleton
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remaining info skeleton
                                Container(
                                  width: 120,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Free label skeleton
                                Container(
                                  width: 40,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
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
          ),
        );
      },
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final Quota quota;
  final VoidCallback onTap;
  final String Function(String?) formatDate;

  const _QuotaCard({
    required this.quota,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMeetingRoom = quota.type == 'MEETING_HOURS';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tr('limits.status')} ${formatDate(quota.endAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Content section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey[300],
                    image: DecorationImage(
                      image: AssetImage(
                        isMeetingRoom
                            ? 'lib/app/assets/images/room.jpg'
                            : 'lib/app/assets/images/print.jpg',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMeetingRoom
                            ? tr('limits.meeting_room')
                            : tr('limits.print'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.textDarkGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tr('limits.remaining'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quota.amount} ${isMeetingRoom ? tr('limits.hour') : tr('limits.pages')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            tr('limits.free'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textDarkGrey,
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
