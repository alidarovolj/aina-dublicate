import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/model/providers/community_cards_provider.dart';
import 'package:aina_flutter/features/coworking/model/models/community_card.dart';
import 'package:aina_flutter/features/coworking/ui/pages/widgets/community_details_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/app/providers/community_card_provider.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/navigation/index.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/ui/blocks/error_refresh_widget.dart';
import 'dart:async';

class CoworkingCommunityPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingCommunityPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingCommunityPage> createState() =>
      _CoworkingCommunityPageState();
}

class _CoworkingCommunityPageState extends ConsumerState<CoworkingCommunityPage>
    with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isLoadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Инициализируем данные только один раз при старте
    final token = ref.read(authProvider).token;
    if (token != null) {
      // Используем один invalidate для обоих провайдеров
      ref.invalidate(communityCardsProvider);
    }
  }

  void _resetPagination() {
    ref.read(communityCardsPageProvider.notifier).state = 1;
    ref.read(communityCardsHasMoreProvider.notifier).state = true;
    ref.read(communityCardsLoadingMoreProvider.notifier).state = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final hasMore = ref.read(communityCardsHasMoreProvider);
      if (!_isLoadingMore && hasMore) {
        setState(() => _isLoadingMore = true);
        ref.read(communityCardsLoadingMoreProvider.notifier).state = true;
        ref.read(communityCardsPageProvider.notifier).state++;
        ref.invalidate(communityCardsProvider(_searchQuery));
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && value != _searchQuery) {
        setState(() => _searchQuery = value);
        _resetPagination();
        ref.invalidate(communityCardsProvider);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final token = ref.read(authProvider).token;
    if (token != null) {
      ref.invalidate(communityCardsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authProvider).token;
    final currentPage = ref.watch(communityCardsPageProvider);
    final hasMorePages = ref.watch(communityCardsHasMoreProvider);
    final isLoadingMore = ref.watch(communityCardsLoadingMoreProvider);
    final communityCardsAsync = ref.watch(communityCardsProvider(_searchQuery));
    final userCardAsync = token != null
        ? ref.watch(communityCardProvider(false))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final cards = ref.watch(communityCardsListProvider) ?? [];

    // Update local state from providers
    _isLoadingMore = isLoadingMore;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.appBg,
                margin: const EdgeInsets.only(top: 64),
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  displacement: 80,
                  onRefresh: () async {
                    _resetPagination();
                    ref.invalidate(communityCardsProvider);
                    ref.invalidate(communityCardProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.appBg,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEEEEEE),
                              width: 1,
                            ),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'community.search'.tr(),
                            hintStyle: const TextStyle(
                              fontSize: 15,
                              color: AppColors.darkGrey,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.grey2,
                              size: 24,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (token != null) ...[
                        userCardAsync.when(
                          data: (userCard) {
                            final status = userCard?['status'] as String?;
                            String buttonText = 'community.create_card'.tr();

                            if (userCard != null &&
                                (status == 'APPROVED' ||
                                    status == 'REJECTED' ||
                                    status == 'UNAPPROVED')) {
                              buttonText = 'community.edit_card'.tr();
                            }

                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: CustomButton(
                                label: buttonText,
                                onPressed: () {
                                  context.pushNamed(
                                    'community_card',
                                    pathParameters: {
                                      'id': widget.coworkingId.toString()
                                    },
                                  );
                                },
                                isFullWidth: true,
                                type: ButtonType.bordered,
                                backgroundColor: AppColors.bgLight,
                                textColor: AppColors.primary,
                              ),
                            );
                          },
                          loading: () => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[100]!,
                              highlightColor: Colors.grey[300]!,
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          error: (error, stack) {
                            if (error.toString().contains('401')) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: CustomButton(
                                label: 'community.create_card'.tr(),
                                onPressed: () {
                                  context.pushNamed(
                                    'community_card',
                                    pathParameters: {
                                      'id': widget.coworkingId.toString()
                                    },
                                  );
                                },
                                isFullWidth: true,
                                type: ButtonType.bordered,
                                backgroundColor: AppColors.bgLight,
                                textColor: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ],
                      _buildCommunityContent(
                        communityCardsAsync,
                        cards,
                        token,
                        hasMorePages,
                      ),
                    ],
                  ),
                ),
              ),
              CustomHeader(
                title: 'community.title'.tr(),
                type: HeaderType.close,
                onBack: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityContent(
    AsyncValue<List<CommunityCard>?> communityCardsAsync,
    List<CommunityCard> cards,
    String? token,
    bool hasMorePages,
  ) {
    return communityCardsAsync.when(
      data: (_) {
        if (cards.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'community.empty'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDarkGrey,
                ),
              ),
            ),
          );
        }

        final groupedCards = _groupCards(cards);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var entry in groupedCards.entries) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey2,
                  ),
                ),
              ),
              ...entry.value.map((user) => _CommunityUserCard(user: user)),
            ],
            if (_isLoadingMore && hasMorePages)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) {
        if (error.toString().contains('401')) {
          if (cards.isEmpty) {
            return _buildSkeletonLoader();
          }

          final groupedCards = _groupCards(cards);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var entry in groupedCards.entries) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey2,
                    ),
                  ),
                ),
                ...entry.value.map((user) => _CommunityUserCard(user: user)),
              ],
            ],
          );
        }

        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return ErrorRefreshWidget(
          height: 300,
          onRefresh: () {
            _resetPagination();
            ref.invalidate(communityCardsProvider);
          },
          errorMessage: is500Error
              ? 'community.error.server'.tr()
              : 'community.error.loading'.tr(),
          refreshText: 'common.refresh'.tr(),
          isCompact: false,
          isServerError: true,
          icon: Icons.warning_amber_rounded,
        );
      },
    );
  }

  Map<String, List<CommunityCard>> _groupCards(List<CommunityCard> cards) {
    final Map<String, List<CommunityCard>> groupedCards = {};

    for (var card in cards) {
      final group = card.name.substring(0, 1).toUpperCase();
      if (!groupedCards.containsKey(group)) {
        groupedCards[group] = [];
      }
      groupedCards[group]?.add(card);
    }

    return groupedCards;
  }

  Widget _buildSkeletonLoader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _CommunityUserCard extends StatelessWidget {
  final CommunityCard user;

  const _CommunityUserCard({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        CommunityDetailsModal.show(context, user: user);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (user.avatar?.url != null && user.avatar!.url.isNotEmpty)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(user.avatar!.url),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.appBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.asset(
                    'lib/app/assets/icons/plain_user.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (user.position != null)
                      Text(
                        user.position!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.grey2,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
