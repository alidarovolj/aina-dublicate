import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/services_provider.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ServicesPage extends ConsumerWidget {
  final int coworkingId;

  const ServicesPage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppColors.appBg,
              margin: const EdgeInsets.only(top: 64),
              child: servicesAsync.when(
                loading: () => _buildSkeletonLoader(),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
                data: (services) => ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            '/coworking/$coworkingId/services/${service.id}',
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (service.image != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        service.image!.url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                        child: Text(
                                          service.title.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            letterSpacing: 0.5,
                                            color: AppColors.primary,
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
                    );
                  },
                ),
              ),
            ),
            const CustomHeader(
              title: 'Услуги',
              type: HeaderType.close,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // Show 5 service card skeletons
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey[300],
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            width: 200,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
