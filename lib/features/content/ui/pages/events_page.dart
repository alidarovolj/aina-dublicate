import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/shared/ui/blocks/events_block.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/types/card_type.dart';

class EventsPage extends ConsumerWidget {
  final String? mallId;

  const EventsPage({
    super.key,
    this.mallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'events.title'.tr(),
              type: HeaderType.pop,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    EventsBlock(
                      mallId: mallId,
                      showTitle: false,
                      showViewAll: false,
                      cardType: PromotionCardType.full,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
