import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/conference_tariff_card.dart';
import 'package:shimmer/shimmer.dart';

class CoworkingConferenceServicePage extends ConsumerWidget {
  final CoworkingService service;
  final List<CoworkingTariff> tariffs;
  final int coworkingId;

  const CoworkingConferenceServicePage({
    super.key,
    required this.service,
    required this.tariffs,
    required this.coworkingId,
  });

  static Widget buildSkeletonLoader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: 3, // Show 3 skeleton items
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const CustomHeader(title: ''),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: tariffs.length,
                  itemBuilder: (context, index) {
                    final tariff = tariffs[index];
                    return ConferenceTariffCard(
                      tariff: tariff,
                      coworkingId: coworkingId,
                      serviceId: service.id,
                      onDetailsTap: () {
                        context.pushNamed(
                          'coworking_calendar',
                          pathParameters: {
                            'id': coworkingId.toString(),
                            'tariffId': tariff.id.toString(),
                          },
                          queryParameters: {
                            'type': 'conference',
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              CustomHeader(
                title: service.title,
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
