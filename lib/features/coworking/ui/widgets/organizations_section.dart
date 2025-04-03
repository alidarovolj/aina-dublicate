import 'package:aina_flutter/features/coworking/model/organization.dart';
import 'package:aina_flutter/features/coworking/model/providers/organization_provider.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class OrganizationsSection extends ConsumerWidget {
  final int coworkingId;
  final VoidCallback? onViewAllTap;
  final bool showTitle;
  final bool showViewAll;
  final bool showDivider;
  final Widget Function(BuildContext)? emptyBuilder;

  const OrganizationsSection({
    Key? key,
    required this.coworkingId,
    this.onViewAllTap,
    this.showTitle = true,
    this.showViewAll = true,
    this.showDivider = true,
    this.emptyBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationsAsync = ref.watch(
      organizationsProvider(
        OrganizationParams(buildingId: coworkingId.toString()),
      ),
    );

    return organizationsAsync.when(
      data: (response) => _buildOrganizationsContent(context, response),
      loading: () => _buildLoadingState(),
      error: (error, stack) {
        print('organizations.error'.tr(args: [error.toString()]));
        return const SizedBox();
      },
    );
  }

  Widget _buildOrganizationsContent(
      BuildContext context, OrganizationsResponse response) {
    if (response.data.isEmpty) {
      return emptyBuilder?.call(context) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'organizations.empty'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textDarkGrey,
                ),
              ),
            ),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle || showViewAll)
          Padding(
            padding: const EdgeInsets.only(
              left: AppLength.xs,
              right: AppLength.xs,
              bottom: AppLength.xxl,
              top: AppLength.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showTitle)
                  Text(
                    'organizations.title'.tr(),
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                if (showViewAll && onViewAllTap != null)
                  TextButton(
                    onPressed: onViewAllTap,
                    child: Row(
                      children: [
                        Text(
                          'organizations.view_all'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                        SvgPicture.asset(
                          'lib/app/assets/icons/chevron-right.svg',
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
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            itemCount: response.data.length,
            itemBuilder: (context, index) {
              return _buildOrganizationCard(context, response.data[index]);
            },
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(
                vertical: AppLength.xs, horizontal: AppLength.xs),
            child: Divider(
              color: Colors.black12,
              thickness: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildOrganizationCard(
      BuildContext context, Organization organization) {
    return GestureDetector(
      onTap: () {
        context.push('/stores/${organization.id}');
      },
      child: Container(
        width: 200,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: organization.previewImage != null
              ? DecorationImage(
                  image: NetworkImage(organization.previewImage!.url),
                  fit: BoxFit.cover,
                )
              : null,
          color: organization.previewImage == null ? Colors.grey[200] : null,
        ),
        child: Stack(
          children: [
            // Градиент снизу для лучшей видимости текста
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Стрелка в правом верхнем углу
            Positioned(
              right: 8,
              top: 8,
              child: SvgPicture.asset(
                'lib/app/assets/icons/linked-arrow.svg',
                width: 24,
                height: 24,
              ),
            ),
            if (organization.categories.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    organization.categories.first.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    organization.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (organization.shortDescription != null)
                    Text(
                      organization.shortDescription!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle || showViewAll)
          Padding(
            padding: const EdgeInsets.all(AppLength.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showTitle)
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 160,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 200,
                  height: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
