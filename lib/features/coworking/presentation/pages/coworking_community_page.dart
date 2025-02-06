import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/providers/community_cards_provider.dart';
import 'package:aina_flutter/features/coworking/domain/models/community_card.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/community_details_modal.dart';
import 'package:shimmer/shimmer.dart';

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

class _CoworkingCommunityPageState
    extends ConsumerState<CoworkingCommunityPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communityCardsAsync = ref.watch(communityCardsProvider(_searchQuery));

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'community.search'.tr(),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search),
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
                  Expanded(
                    child: communityCardsAsync.when(
                      data: (cards) {
                        final groupedCards = _groupCards(cards);

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

                        return ListView.builder(
                          itemCount: groupedCards.length,
                          itemBuilder: (context, index) {
                            final letter = groupedCards.keys.elementAt(index);
                            final users = groupedCards[letter]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    letter,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDarkGrey,
                                    ),
                                  ),
                                ),
                                ...users.map(
                                    (user) => _CommunityUserCard(user: user)),
                              ],
                            );
                          },
                        );
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        CommunityDetailsModal.show(context, user: user);
      },
      child: Container(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(
                    user.avatar?.url ??
                        'https://ionicframework.com/docs/img/demos/avatar.svg',
                  ),
                  fit: BoxFit.cover,
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
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
