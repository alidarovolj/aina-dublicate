import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/app/providers/requests/stores/store_details_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  error: (error, stack) => Center(
                    child: Text('stores.error'.tr(args: [error.toString()])),
                  ),
                  data: (storeData) => CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                (() {
                                  // Проверяем валидность URL изображения
                                  final String? imageUrl =
                                      storeData['preview_image']?['url'];
                                  final bool isValidImageUrl =
                                      imageUrl != null &&
                                          imageUrl.isNotEmpty &&
                                          !imageUrl.contains('HTTP') &&
                                          !imageUrl
                                              .toLowerCase()
                                              .contains('error') &&
                                          imageUrl.startsWith('http') &&
                                          !imageUrl.contains('404') &&
                                          !imageUrl.contains('500') &&
                                          !imageUrl.contains('403');

                                  if (isValidImageUrl) {
                                    return Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 212,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'lib/app/assets/images/no_photo.png',
                                          width: double.infinity,
                                          height: 212,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    );
                                  } else {
                                    return Image.asset(
                                      'lib/app/assets/images/no_photo.png',
                                      width: double.infinity,
                                      height: 212,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                })(),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.5),
                                        ],
                                        stops: const [0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Text(
                                    storeData['short_description'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                    icon: 'lib/app/assets/icons/time.svg',
                                    text: storeData['working_hours'] ??
                                        '10:00-22:00',
                                    label: 'stores.working_hours'.tr(),
                                  ),
                                  const SizedBox(height: 16),
                                  if (storeData['buildings']?.isNotEmpty ??
                                      false) ...[
                                    _InfoRow(
                                      icon: 'lib/app/assets/icons/location.svg',
                                      text: storeData['buildings'][0]
                                              ['address'] ??
                                          'stores.on_map'.tr(),
                                      label: 'stores.on_map'.tr(),
                                      onTap: () {
                                        final lat = storeData['buildings'][0]
                                            ['latitude'];
                                        final lng = storeData['buildings'][0]
                                            ['longitude'];
                                        if (lat != null && lng != null) {
                                          final uri = Uri.parse(
                                              'https://2gis.kz/almaty/routeSearch/to/$lng,$lat');
                                          launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
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
                                          'lib/app/assets/icons/instagram.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(
                                              Colors.white, BlendMode.srcIn),
                                        ),
                                        onPressed: () async {
                                          final uri = Uri.parse(
                                              storeData['instagram_link']);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
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
                                        label: 'stores.visit_website'.tr(),
                                        type: ButtonType.bordered,
                                        isFullWidth: true,
                                        icon: SvgPicture.asset(
                                          'lib/app/assets/icons/language.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(
                                              Colors.black, BlendMode.srcIn),
                                        ),
                                        onPressed: () async {
                                          final uri = Uri.parse(
                                              storeData['website_link']);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
  final String icon;
  final String text;
  final VoidCallback? onTap;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
    required this.label,
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
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                ),
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
