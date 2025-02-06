import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/mall_events_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class EventsBlock extends ConsumerWidget {
  final String mallId;
  final VoidCallback? onViewAllTap;

  const EventsBlock({
    super.key,
    required this.mallId,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(mallEventsProvider(mallId));

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'events.no_active_events'.tr(),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textDarkGrey,
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Text(
              'events.no_active_events'.tr(),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDarkGrey,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.previewImage != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        event.previewImage!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error_outline),
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'events.views_count'
                              .tr(args: [event.views.toString()]),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
