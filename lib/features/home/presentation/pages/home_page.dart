import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/types/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/stories_list.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/core/providers/requests/banners_provider.dart';
import 'package:aina_flutter/core/widgets/buildings_list.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:aina_flutter/core/widgets/home_promotions_block.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/utils/button_navigation_handler.dart';
import 'package:aina_flutter/core/types/button_config.dart';
import 'package:aina_flutter/core/router/route_observer.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(promotionsProvider.notifier)
            .fetchPromotions(context, forceRefresh: true);
        ref.read(bannersProvider.notifier).fetchBanners(forceRefresh: true);
        ref.refresh(settingsProvider);
        _checkAuthAndFetchProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(promotionsProvider.notifier)
            .fetchPromotions(context, forceRefresh: true);
        ref.read(bannersProvider.notifier).fetchBanners(forceRefresh: true);
        ref.refresh(settingsProvider);
        _checkAuthAndFetchProfile();
      }
    });
  }

  Future<void> _checkAuthAndFetchProfile() async {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.token != null) {
      try {
        final response = await ApiClient().dio.get('/api/promenade/profile');
        if (!mounted) return;
        if (response.data['success'] == true && response.data['data'] != null) {
          ref.read(authProvider.notifier).updateUserData(response.data['data']);
        }
      } catch (error) {
        // print('Error fetching profile: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final promotionsAsync = ref.watch(promotionsProvider);
    // print('show token ${ref.read(authProvider).token}');

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Container(
            color: AppColors.appBg,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: UpperHeader(),
                ),
                const SliverToBoxAdapter(
                  child: StoryList(),
                ),
                SliverToBoxAdapter(
                  child: bannersAsync.when(
                    loading: () => Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppLength.xs,
                          vertical: AppLength.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (banners) {
                      // print('Banners data received: ${banners.length} banners');
                      return CarouselWithIndicator(
                        slideList: banners,
                        showIndicators: true,
                        onSlideClick: (slide) {
                          // print('Slide clicked: ${slide.id}');
                          if (slide.button == null) return;

                          final button = slide.button!;
                          ButtonNavigationHandler.handleNavigation(
                            context,
                            ref,
                            ButtonConfig(
                              label: button.label,
                              color: button.color,
                              isInternal: button.isInternal,
                              link: button.link,
                              internal: button.isInternal == true &&
                                      button.internal != null
                                  ? ButtonInternal(
                                      model: button.internal!.model,
                                      id: button.internal!.id ?? 0,
                                      buildingType:
                                          button.internal!.buildingType ?? '',
                                      isAuthRequired:
                                          button.internal!.isAuthRequired,
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: BuildingsList(),
                ),
                const SliverToBoxAdapter(
                  child: HomePromotionsBlock(
                    showTitle: true,
                    showViewAll: false,
                    showDivider: false,
                    cardType: PromotionCardType.small,
                    maxElements: 2,
                    sortByQr: true,
                    showArrow: true,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: AppLength.xxxl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
