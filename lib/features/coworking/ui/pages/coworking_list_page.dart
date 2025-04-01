import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';

class CoworkingListPage extends ConsumerWidget {
  const CoworkingListPage({super.key});

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppLength.xs),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppLength.xs),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppColors.appBg,
              margin: const EdgeInsets.only(top: 64), // Height of CustomHeader
              child: buildingsAsync.when(
                loading: () => _buildSkeletonLoader(),
                error: (error, stack) => Center(
                  child: Text('coworking.error'.tr(args: [error.toString()])),
                ),
                data: (buildings) {
                  final coworkings = buildings['coworking'] ?? [];
                  if (coworkings.isEmpty) {
                    return Center(
                      child: Text(
                        'coworking.no_coworkings'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textDarkGrey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppLength.xs),
                    itemCount: coworkings.length,
                    itemBuilder: (context, index) {
                      final coworking = coworkings[index];
                      return GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            'coworking_details',
                            pathParameters: {'id': coworking.id.toString()},
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(coworking.previewImage.url),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  coworking.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  coworking.address ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            CustomHeader(
              title: 'coworking.title'.tr(),
              type: HeaderType.pop,
            ),
          ],
        ),
      ),
    );
  }
}
