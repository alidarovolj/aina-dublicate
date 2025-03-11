import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/types/building.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class BuildingsList extends ConsumerWidget {
  const BuildingsList({super.key});

  void _logShoppingMallClick(Building mall) {
    String platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

    AmplitudeService().logEvent(
      'shopping_mall_click',
      eventProperties: {
        'Platform': platform,
        'mall_name': mall.name,
      },
    );
  }

  Widget _buildMallRow(List<Building> buildings, BuildContext context) {
    if (buildings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLength.xs,
            vertical: AppLength.sm,
          ),
          child: Text(
            'buildings.mall'.tr(),
            style: GoogleFonts.lora(
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          child: Row(
            children: buildings
                .asMap()
                .entries
                .map((entry) => GestureDetector(
                      onTap: () {
                        _logShoppingMallClick(entry.value);
                        context.push('/malls/${entry.value.id}');
                      },
                      child: Container(
                        width: (MediaQuery.of(context).size.width -
                                30 -
                                (AppLength.xs * 2)) /
                            3,
                        height: 142,
                        margin: EdgeInsets.only(
                          right: entry.key < buildings.length - 1 ? 15 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(entry.value.previewImage.url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoworkingRow(List<Building> buildings, BuildContext context) {
    if (buildings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLength.xs,
            vertical: AppLength.sm,
          ),
          child: Text(
            'buildings.coworking'.tr(),
            style: GoogleFonts.lora(
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...buildings.asMap().entries.map((entry) => GestureDetector(
                      onTap: () {
                        context.push('/coworking/${entry.value.id}');
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5 -
                            (AppLength.xs + 7.5),
                        height: 94,
                        margin: EdgeInsets.only(
                          right: entry.key < buildings.length - 1 ? 15 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(entry.value.previewImage.url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: () {
                    if (buildings.isNotEmpty) {
                      context.go('/coworking/${buildings[0].id}/services');
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5 -
                        (AppLength.xs + 7.5),
                    height: 94,
                    margin: const EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'lib/core/assets/images/rent.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: SvgPicture.asset(
                            'lib/core/assets/icons/linked-arrow.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Text(
                            'services.title'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return buildingsAsync.when(
      loading: () => _buildSkeletonLoader(context),
      error: (error, stack) {
        print('❌ Ошибка при загрузке зданий: $error');

        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return ErrorRefreshWidget(
          onRefresh: () {
            print('🔄 Обновление списка зданий...');
            Future.microtask(() async {
              try {
                ref.refresh(buildingsProvider);
              } catch (e) {
                print('❌ Ошибка при обновлении списка зданий: $e');
              }
            });
          },
          errorMessage: is500Error
              ? 'stories.error.server'.tr()
              : 'stories.error.loading'.tr(),
          refreshText: 'common.refresh'.tr(),
          icon: Icons.warning_amber_rounded,
          isServerError: true,
        );
      },
      data: (buildings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoworkingRow(buildings['coworking'] ?? [], context),
          _buildMallRow(buildings['mall'] ?? [], context),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coworking skeleton
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLength.xs,
            vertical: AppLength.sm,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          child: Row(
            children: List.generate(2, (index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5 -
                      (AppLength.xs + 7.5),
                  height: 94,
                  margin: EdgeInsets.only(right: index < 1 ? 15 : 0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),

        // Mall skeleton
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLength.xs,
            vertical: AppLength.sm,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
          child: Row(
            children: List.generate(3, (index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: (MediaQuery.of(context).size.width -
                          30 -
                          (AppLength.xs * 2)) /
                      3,
                  height: 142,
                  margin: EdgeInsets.only(right: index < 2 ? 15 : 0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
