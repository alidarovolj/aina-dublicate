import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/stories_list.dart';
import 'package:aina_flutter/widgets/base_slider.dart';
import 'package:aina_flutter/widgets/upper_header.dart';
import 'package:aina_flutter/app/providers/requests/banners_provider.dart';
import 'package:aina_flutter/widgets/buildings_list.dart';
import 'package:aina_flutter/app/providers/requests/promotions_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class Malls extends ConsumerStatefulWidget {
  const Malls({super.key});

  @override
  ConsumerState<Malls> createState() => _MallsState();
}

class _MallsState extends ConsumerState<Malls> {
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
                      showIndicators: true,
                      height: 125,
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
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppLength.xs,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image:
                                      NetworkImage(promotion.previewImage.url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              height: 94,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      // gradient: LinearGradient(
                                      //   begin: Alignment.topCenter,
                                      //   end: Alignment.bottomCenter,
                                      //   colors: [
                                      //     Colors.transparent,
                                      //     Colors.black.withOpacity(0.7),
                                      //   ],
                                      // ),
                                    ),
                                  ),
                                ],
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
