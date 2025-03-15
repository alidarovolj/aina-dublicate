import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/mall_events_provider.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aina_flutter/features/general/events/presentation/pages/event_details_page.dart';

class EventsBlock extends ConsumerWidget {
  final String? mallId;
  final VoidCallback? onViewAllTap;
  final bool showTitle;
  final bool showViewAll;
  final bool showDivider;
  final PromotionCardType cardType;
  final bool showGradient;
  final Widget Function(BuildContext)? emptyBuilder;
  final int? maxElements;
  final bool sortByQr;
  final bool showArrow;
  final List<Promotion>? events;

  static DateTime? _lastTap;
  static const _debounceTime = Duration(milliseconds: 500);

  const EventsBlock({
    super.key,
    this.mallId,
    this.onViewAllTap,
    this.showTitle = true,
    this.showViewAll = true,
    this.showDivider = true,
    this.cardType = PromotionCardType.medium,
    this.showGradient = false,
    this.emptyBuilder,
    this.maxElements,
    this.sortByQr = false,
    this.showArrow = false,
    this.events,
  });

  List<dynamic> _sortPromotions(List<dynamic> promotions) {
    if (!sortByQr) return promotions;

    return List<dynamic>.from(promotions)
      ..sort((a, b) {
        final aPromotion = a as Promotion;
        final bPromotion = b as Promotion;
        if (aPromotion.isQr == bPromotion.isQr) return 0;
        return aPromotion.isQr ? -1 : 1;
      });
  }

  void _logEventClick(BuildContext context, Promotion event) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'event_click',
      eventProperties: {
        'Platform': platform,
        'event_id': event.id,
        'event_title': event.title,
      },
    );
  }

  void _handleEventTap(BuildContext context, Promotion event) {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < _debounceTime) {
      return;
    }
    _lastTap = now;

    _logEventClick(context, event);

    // Use push instead of pushNamed for more direct control
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(id: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = events != null
        ? AsyncValue.data(events!)
        : (mallId != null
            ? ref.watch(mallEventsPromotionProvider(mallId!))
            : const AsyncValue.data([]));

    return eventsAsync.when(
      loading: () => _buildShimmer(context),
      error: (error, stack) {
        print('❌ Error loading events: $error');

        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return ErrorRefreshWidget(
          onRefresh: () {
            print('🔄 Refreshing events...');
            Future.microtask(() async {
              try {
                ref.refresh(mallEventsPromotionProvider(mallId!));
              } catch (e) {
                print('❌ Error refreshing events: $e');
              }
            });
          },
          errorMessage: is500Error
              ? 'events.error.server'.tr()
              : 'events.error.loading'.tr(),
          refreshText: 'common.refresh'.tr(),
          icon: Icons.warning_amber_rounded,
          isServerError: true,
        );
      },
      data: (events) {
        if (events.isEmpty) {
          return const SizedBox.shrink();
        }

        final sortedEvents = _sortPromotions(events).cast<Promotion>();

        return Column(
          children: [
            if (showTitle || showViewAll)
              Padding(
                padding: const EdgeInsets.only(
                    left: AppLength.xs,
                    bottom: AppLength.xs,
                    top: AppLength.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showTitle)
                      Text(
                        'events.title'.tr(),
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    if (showViewAll && onViewAllTap != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          if (onViewAllTap != null) {
                            onViewAllTap?.call();
                          } else if (mallId != null) {
                            context.pushNamed(
                              'mall_promotions',
                              pathParameters: {'id': mallId.toString()},
                              extra: {'initialTabIndex': 1},
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              'promotions.view_all'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            SvgPicture.asset(
                              'lib/core/assets/icons/chevron-right.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textDarkGrey,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            switch (cardType) {
              PromotionCardType.medium =>
                _buildMediumCardList(context, sortedEvents),
              PromotionCardType.full =>
                _buildFullCardList(context, sortedEvents),
              PromotionCardType.small =>
                _buildSmallCardGrid(context, sortedEvents),
            },
            if (showDivider) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLength.xs),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    switch (cardType) {
      case PromotionCardType.medium:
        return SizedBox(
          height: 201,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 124,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      case PromotionCardType.full:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          itemCount: 2,
          itemBuilder: (context, index) {
            return Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        );
      case PromotionCardType.small:
        final screenWidth = MediaQuery.of(context).size.width;
        const horizontalPadding = AppLength.xs * 2;
        const itemSpacing = 12.0;
        const itemCount = 3;
        const totalSpacing = itemSpacing * (itemCount - 1);
        final availableWidth = screenWidth - horizontalPadding - totalSpacing;
        final itemWidth = availableWidth / itemCount;

        return SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                width: itemWidth,
                margin: EdgeInsets.only(
                    right: index != itemCount - 1 ? itemSpacing : 0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildMediumCardList(BuildContext context, List<Promotion> events) {
    final limitedEvents =
        maxElements != null ? events.take(maxElements!).toList() : events;

    return SizedBox(
      height: 201,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: limitedEvents.length,
        itemBuilder: (context, index) {
          final event = limitedEvents[index];
          return GestureDetector(
            onTap: () => _handleEventTap(context, event),
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _buildImageWithGradient(event.previewImage.url),
                      if (showArrow)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: SvgPicture.asset(
                            'lib/core/assets/icons/linked-arrow.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.formattedDateRange,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDarkGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullCardList(BuildContext context, List<Promotion> events) {
    final limitedEvents =
        maxElements != null ? events.take(maxElements!).toList() : events;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
      itemCount: limitedEvents.length,
      itemBuilder: (context, index) {
        final event = limitedEvents[index];
        return GestureDetector(
          onTap: () => _handleEventTap(context, event),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                _buildImageWithGradient(
                  event.previewImage.url,
                  height: 200,
                  borderRadius: 8,
                ),
                if (showArrow)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SvgPicture.asset(
                      'lib/core/assets/icons/linked-arrow.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.formattedDateRange,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallCardGrid(BuildContext context, List<Promotion> events) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AppLength.xs * 2;
    const itemSpacing = 12.0;
    final totalSpacing = itemSpacing * (events.length - 1);
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final itemWidth = availableWidth / events.length;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return GestureDetector(
            onTap: () => _handleEventTap(context, event),
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(
                  right: index != events.length - 1 ? itemSpacing : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(event.previewImage.url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWithGradient(String imageUrl,
      {double height = 124, double borderRadius = 4.0}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: showGradient
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
