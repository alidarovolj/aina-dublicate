import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/types/building.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class BuildingsList extends ConsumerWidget {
  const BuildingsList({super.key});

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
            'ТРЦ',
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
                        context.pushNamed(
                          'mall_details',
                          pathParameters: {'id': entry.value.id.toString()},
                        );
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
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3),
                              BlendMode.darken,
                            ),
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
            'Коворкинги',
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
                .map((entry) => Container(
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
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return buildingsAsync.when(
      loading: () => _buildSkeletonLoader(context),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
