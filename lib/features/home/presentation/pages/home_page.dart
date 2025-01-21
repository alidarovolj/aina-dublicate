import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/stories_list.dart';
import 'package:aina_flutter/core/widgets/base_slider.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/core/providers/requests/banners_provider.dart';
import 'package:aina_flutter/core/widgets/buildings_list.dart';
import 'package:aina_flutter/core/providers/requests/promotions_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final promotionsAsync = ref.watch(promotionsProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Container(
            color: AppColors.white,
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (banners) => CarouselWithIndicator(
                      slideList: banners,
                      showIndicators: false,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: BuildingsList(),
                ),
                SliverToBoxAdapter(
                  child: promotionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (promotions) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLength.xs,
                            vertical: AppLength.sm,
                          ),
                          child: Text(
                            'Акции',
                            style: GoogleFonts.lora(
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: promotions.length,
                          itemBuilder: (context, index) {
                            final promotion = promotions[index];
                            return GestureDetector(
                              onTap: () {
                                context.pushNamed(
                                  'promotion_details',
                                  pathParameters: {
                                    'id': promotion.id.toString()
                                  },
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppLength.xs,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        promotion.previewImage.url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                height: 94,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
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
