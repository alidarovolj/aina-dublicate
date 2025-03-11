import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/providers/community_cards_provider.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/community_details_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/providers/community_card_provider.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/router/route_observer.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

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
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    super.initState();
    // Используем Future.microtask чтобы избежать setState во время build
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.invalidate(communityCardsProvider);
        ref.invalidate(communityCardProvider);
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
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
    final communityCardsAsync = ref.watch(communityCardsProvider(_searchQuery));
    final userCardAsync =
        token != null ? ref.watch(communityCardProvider(true)) : null;

    return Container(
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  if (token != null) ...[
                    userCardAsync?.when(
                          data: (userCard) {
                            if (userCard['status'] != 'APPROVED') {
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
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ) ??
                        const SizedBox.shrink(),
                  ],
                  Expanded(
                    child: communityCardsAsync.when(
                      data: (cards) {
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

                        final groupedCards = _groupCards(cards);

                        if (token != null) {
                          return userCardAsync?.when(
                                data: (userCard) {
                                  if (userCard['status'] == 'APPROVED') {
                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
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
                                            user: CommunityCard.fromJson(
                                                userCard),
                                          ),
                                          if (cards.isNotEmpty) ...[
                                            for (var entry
                                                in groupedCards.entries) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
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
                                                  _CommunityUserCard(
                                                      user: user)),
                                            ],
                                          ],
                                        ],
                                      ),
                                    );
                                  }
                                  return _buildCardsList(groupedCards);
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, __) => _buildCardsList(groupedCards),
                              ) ??
                              _buildCardsList(groupedCards);
                        }

                        return _buildCardsList(groupedCards);
                      },
                      loading: () => _buildSkeletonLoader(),
                      error: (error, stack) => Center(
                        child: Text(
                          'community.error'.tr(args: [error.toString()]),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomHeader(
              title: 'community.title'.tr(),
              type: HeaderType.close,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(Map<String, List<CommunityCard>> groupedCards) {
    return SingleChildScrollView(
      child: Column(
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

  const _CommunityUserCard({
    required this.user,
  });

  String _getInitials() {
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
