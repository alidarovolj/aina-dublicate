import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/providers/community_cards_provider.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';
import 'package:aina_flutter/pages/coworking/widgets/community_details_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/app/providers/community_card_provider.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/shared/navigation/index.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';

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
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
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
    // Используем Future.microtask чтобы избежать setState во время build
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      if (token != null) {
        _resetPagination();
        ref.invalidate(communityCardsProvider);
        ref.invalidate(communityCardProvider);
      }
    });
  }

  void _resetPagination() {
    ref.read(communityCardsPageProvider.notifier).state = 1;
    ref.read(communityCardsHasMoreProvider.notifier).state = true;
    ref.read(communityCardsLoadingMoreProvider.notifier).state = false;
    ref.read(communityCardsListProvider.notifier).state = null;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMorePages) {
        _isLoadingMore = true;
        ref.read(communityCardsLoadingMoreProvider.notifier).state = true;
        ref.read(communityCardsPageProvider.notifier).state++;
        // Загружаем следующую страницу без обновления всего списка
        ref.invalidate(communityCardsProvider(_searchQuery));
      }
    }
  }

  void _onSearchChanged(String value) {
    debugPrint('Search value changed to: $value');
    setState(() {
      _searchQuery = value;
    });
    _resetPagination();
    ref.invalidate(communityCardsProvider);
  }

  @override
  void dispose() {
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
      ref.invalidate(communityCardProvider);
    }
  }

  Map<String, List<CommunityCard>> _groupCards(List<CommunityCard> cards) {
    final groups = <String, List<CommunityCard>>{};

    for (var card in cards) {
      final firstLetter = card.name[0].toUpperCase();
      if (!groups.containsKey(firstLetter)) {
        groups[firstLetter] = [];
      }
      groups[firstLetter]!.add(card);
    }

    return Map.fromEntries(
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authProvider).token;
    final currentPage = ref.watch(communityCardsPageProvider);
    final hasMorePages = ref.watch(communityCardsHasMoreProvider);
    final isLoadingMore = ref.watch(communityCardsLoadingMoreProvider);
    final communityCardsAsync = ref.watch(communityCardsProvider(_searchQuery));
    final userCardAsync =
        token != null ? ref.watch(communityCardProvider(false)) : null;
    final cards = ref.watch(communityCardsListProvider) ?? [];

    debugPrint('Current search query: $_searchQuery');
    debugPrint('Cards length: ${cards.length}');
    debugPrint('Community cards async state: $communityCardsAsync');

    // Update local state from providers
    _currentPage = currentPage;
    _hasMorePages = hasMorePages;
    _isLoadingMore = isLoadingMore;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Если свайп слева направо (положительная скорость) и достаточно быстрый
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
                child: Column(
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
                      userCardAsync?.when(
                            data: (userCard) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: CustomButton(
                                  label: (userCard != null &&
                                          (userCard['status'] == 'APPROVED' ||
                                              userCard['status'] == 'REJECTED'))
                                      ? 'community.edit_card'.tr()
                                      : 'community.create_card'.tr(),
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
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => Padding(
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
                            ),
                          ) ??
                          Padding(
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
                          ),
                    ],
                    Expanded(
                      child: communityCardsAsync.when(
                        data: (_) {
                          debugPrint(
                              'Rendering data state with cards: ${cards.length}');
                          if (cards.isEmpty) {
                            return Center(
                              child: Text(
                                'community.empty'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                            );
                          }

                          // Разделяем карточки на карточку пользователя и остальные
                          List<CommunityCard> otherCards = List.from(cards);
                          CommunityCard? userCard;

                          if (token != null && cards.isNotEmpty) {
                            try {
                              final firstCard = cards.first;
                              if (firstCard.status == 'APPROVED' ||
                                  firstCard.status == 'REJECTED') {
                                userCard = firstCard;
                                otherCards = cards.skip(1).toList();
                              }
                            } catch (e) {
                              debugPrint('Error finding user card: $e');
                            }
                          }

                          final groupedCards = _groupCards(otherCards);
                          debugPrint(
                              'Grouped cards: ${groupedCards.length} groups');

                          return SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userCard != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'community.you'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.grey2,
                                      ),
                                    ),
                                  ),
                                  _CommunityUserCard(
                                    user: userCard,
                                    isCurrentUser: true,
                                  ),
                                ],
                                if (groupedCards.isNotEmpty) ...[
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
                                    ...entry.value.map((user) =>
                                        _CommunityUserCard(user: user)),
                                  ],
                                ] else if (userCard == null) ...[
                                  Center(
                                    child: Text(
                                      'community.empty'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textDarkGrey,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) {
                          debugPrint('Error state: $error');
                          // Если ошибка 401, показываем пустой список вместо сообщения об ошибке
                          if (error.toString().contains('401')) {
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'community.other_members'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.grey2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Для других ошибок показываем сообщение об ошибке
                          return Center(
                            child: Text(
                              'community.error'.tr(args: [error.toString()]),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 3, // Show 3 letter groups
      itemBuilder: (context, groupIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letter header skeleton
            Padding(
              padding: const EdgeInsets.all(12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // User cards skeleton
            ...List.generate(
              4, // Show 4 users per letter group
              (index) => Container(
                padding: const EdgeInsets.all(12),
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
                    // Avatar skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name skeleton
                          Shimmer.fromColors(
                            baseColor: Colors.grey[100]!,
                            highlightColor: Colors.grey[300]!,
                            child: Container(
                              width: 150,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Position skeleton
                          Shimmer.fromColors(
                            baseColor: Colors.grey[100]!,
                            highlightColor: Colors.grey[300]!,
                            child: Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommunityUserCard extends StatelessWidget {
  final CommunityCard user;
  final bool isCurrentUser;

  const _CommunityUserCard({
    required this.user,
    this.isCurrentUser = false,
  });

  String _getInitials() {
    if (isCurrentUser) {
      return 'community.you'.tr();
    }
    final nameParts = user.name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

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
