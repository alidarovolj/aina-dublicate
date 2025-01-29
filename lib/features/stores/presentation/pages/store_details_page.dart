import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/providers/requests/stores/store_details_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:shimmer/shimmer.dart';

class StoreDetailsPage extends ConsumerWidget {
  final String? id;
  final Map<String, dynamic>? store;

  const StoreDetailsPage({
    super.key,
    this.store,
    this.id,
  }) : assert(
            store != null || id != null, 'Either store or id must be provided');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = id != null
        ? ref.watch(storeDetailsProvider(id!))
        : AsyncValue.data(store!);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                margin: const EdgeInsets.only(top: 64),
                child: storeAsync.when(
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (storeData) => CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                storeData['preview_image']?['url'] != null
                                    ? Image.network(
                                        storeData['preview_image']['url'],
                                        width: double.infinity,
                                        height: 212,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: 212,
                                        color: AppColors.grey2,
                                        child: const Center(
                                          child: Icon(
                                            Icons.store,
                                            size: 48,
                                            color: AppColors.grey2,
                                          ),
                                        ),
                                      ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                        stops: const [0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  child: Text(
                                    storeData['short_description'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoRow(
                                    icon: Icons.access_time,
                                    text: storeData['working_hours'] ??
                                        '10:00-22:00',
                                  ),
                                  const SizedBox(height: 16),
                                  if (storeData['buildings']?.isNotEmpty ??
                                      false) ...[
                                    _InfoRow(
                                      icon: Icons.location_on,
                                      text: storeData['buildings'][0]
                                              ['address'] ??
                                          'На карте',
                                      onTap: () {
                                        // TODO: Open map with coordinates
                                        final lat = storeData['buildings'][0]
                                            ['latitude'];
                                        final lng = storeData['buildings'][0]
                                            ['longitude'];
                                      },
                                    ),
                                  ],
                                  if (storeData['description'] != null) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Html(
                                        data: storeData['description'],
                                        style: {
                                          "body": Style(
                                            fontSize: FontSize(16),
                                            color: AppColors.textDarkGrey,
                                            margin: Margins.zero,
                                            padding: HtmlPaddings.zero,
                                          ),
                                        },
                                      ),
                                    ),
                                  ],
                                  if (storeData['instagram_link']?.isNotEmpty ??
                                      false) ...[
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: CustomButton(
                                        label: 'Instagram',
                                        type: ButtonType.filled,
                                        isFullWidth: true,
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/instagram.svg',
                                          width: 24,
                                          height: 24,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          print(
                                              'Opening Instagram: ${storeData['instagram_link']}');
                                        },
                                      ),
                                    ),
                                  ],
                                  if (storeData['website_link']?.isNotEmpty ??
                                      false) ...[
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: CustomButton(
                                        label: 'Перейти на сайт',
                                        type: ButtonType.bordered,
                                        isFullWidth: true,
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/language.svg',
                                          width: 24,
                                          height: 24,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          print(
                                              'Opening website: ${storeData['website_link']}');
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomHeader(
                title: storeAsync.when(
                  data: (storeData) => storeData['name'] ?? '',
                  loading: () => '',
                  error: (_, __) => '',
                ),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: double.infinity,
                  height: 212,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonInfoRow(),
                    const SizedBox(height: 16),
                    _buildSkeletonInfoRow(),
                    const SizedBox(height: 24),
                    // Description skeleton
                    ...List.generate(
                        4,
                        (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[100]!,
                                highlightColor: Colors.grey[300]!,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            )),
                    const SizedBox(height: 24),
                    // Buttons skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonInfoRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Icon(icon, color: AppColors.textDarkGrey),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDarkGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Divider(height: 1, color: AppColors.lightGrey),
        ),
      ],
    );
  }
}
