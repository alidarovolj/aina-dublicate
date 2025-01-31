import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';

class CoworkingBookingsPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingBookingsPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingBookingsPage> createState() =>
      _CoworkingBookingsPageState();
}

class _CoworkingBookingsPageState extends ConsumerState<CoworkingBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 64),
              child: !authState.isAuthenticated
                  ? _buildUnauthorizedState()
                  : _buildAuthorizedState(),
            ),
            CustomHeader(
              title: 'coworking_tabs.bookings'.tr(),
              type: HeaderType.close,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizedState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                SizedBox(
                  width: double.infinity,
                  child: Tab(text: 'bookings.active'.tr()),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Tab(text: 'bookings.history'.tr()),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(true),
              _buildBookingsList(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthorizedState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'bookings.auth_required'.tr(),
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
            label: 'bookings.authorize'.tr(),
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

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'bookings.no_bookings'.tr(),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                label: 'bookings.book_coworking'.tr(),
                type: ButtonType.filled,
                isFullWidth: true,
                onPressed: () {
                  // Handle coworking booking
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'bookings.book_conference'.tr(),
                type: ButtonType.bordered,
                isFullWidth: true,
                onPressed: () {
                  // Handle conference room booking
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBookingsList(bool isActive) {
    // This is a placeholder. Replace with actual booking data
    final List<Map<String, dynamic>> bookings = [];

    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking['title'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(booking['time'] ?? ''),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(booking['date'] ?? ''),
              ],
            ),
            if (booking['status'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking['status'] == 'active'
                      ? Colors.green[100]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking['status'] ?? '',
                  style: TextStyle(
                    color: booking['status'] == 'active'
                        ? Colors.green[700]
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
