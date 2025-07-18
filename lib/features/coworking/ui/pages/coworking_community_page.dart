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
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';
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
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
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
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchQuery != _searchController.text) {
          setState(() {
            _searchQuery = _searchController.text;
          });
          _resetPagination();
        }
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        ref.read(communityCardsHasMoreProvider)) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    ref.read(communityCardsLoadingMoreProvider.notifier).state = true;
    ref.read(communityCardsPageProvider.notifier).state++;
  }

  void _resetPagination() {
    ref.read(communityCardsPageProvider.notifier).state = 1;
    ref.read(communityCardsHasMoreProvider.notifier).state = true;
    ref.read(communityCardsLoadingMoreProvider.notifier).state = false;
    ref.read(communityCardsListProvider.notifier).state = null;
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
      _resetPagination();
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

    // Убираем пустые группы и сортируем
    final filteredGroups = groups.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(filteredGroups);
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

    debugPrint('Current search query: $_searchQuery');
    debugPrint('Cards length: ${cards.length}');
    debugPrint('Community cards async state: $communityCardsAsync');

    // Update local state from providers
    _currentPage = currentPage;
    _hasMorePages = hasMorePages;
    _isLoadingMore = isLoadingMore;

    // Если текущее состояние - ошибка 401, и список пуст, попробуем обновить данные
    if (communityCardsAsync is AsyncError &&
        communityCardsAsync.error.toString().contains('401') &&
        cards.isEmpty) {
      // Попытка перезагрузить данные для отображения списка других пользователей
      Future.microtask(() {
        if (mounted) {
          _resetPagination();
          ref.invalidate(communityCardsProvider);
        }
      });
    }

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
                        ),
                      ),
                      if (token != null) ...[
                        FutureBuilder<Map<String, dynamic>?>(
                          future: ApiClient()
                              .dio
                              .get(
                                '/api/promenade/community-card',
                                options: Options(
                                  headers: {'force-refresh': 'true'},
                                ),
                              )
                              .then((response) {
                            if (response.data is Map<String, dynamic> &&
                                response.data['success'] == true &&
                                response.data['data'] != null) {
                              return response.data['data']
                                  as Map<String, dynamic>;
                            }
                            return null;
                          }).catchError((e) {
                            debugPrint('Error fetching user card: $e');
                            // Для ошибки 401 просто возвращаем null, но не блокируем отображение
                            if (e is DioException &&
                                e.response?.statusCode == 401) {
                              debugPrint('401 error - not showing button');
                              throw e; // Пробрасываем ошибку 401, чтобы кнопка не отображалась
                            }
                            // Другие ошибки пробрасываем дальше
                            throw e;
                          }),
                          builder: (context, snapshot) {
                            // При ошибке 401 не показываем кнопку вообще
                            if (snapshot.hasError) {
                              final error = snapshot.error;
                              debugPrint('Error in user card snapshot: $error');
                              if (error is DioException &&
                                  error.response?.statusCode == 401) {
                                // Не показываем кнопку при 401
                                return const SizedBox.shrink();
                              }

                              // Для других ошибок показываем кнопку создания
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

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // Показываем скелетон для кнопки
                              return Padding(
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
                              );
                            }

                            final userCard = snapshot.data;
                            final status = userCard?['status'] as String?;

                            debugPrint(
                                'Direct API call - User card status: $status');

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
                        ),
                      ],
                      _buildCommunityContent(
                        communityCardsAsync,
                        cards,
                        token,
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
  ) {
    return communityCardsAsync.when(
      data: (_) {
        debugPrint('Rendering data state with cards: ${cards.length}');
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

        // Разделяем карточки на карточку пользователя и остальные
        List<CommunityCard> otherCards = [];
        CommunityCard? userCard;

        if (token != null && cards.isNotEmpty) {
          // Первая карточка может быть карточкой пользователя
          final firstCard = cards.first;

          // Проверяем, является ли первая карточка карточкой пользователя с правильным статусом
          if (firstCard.status == 'APPROVED') {
            userCard = firstCard;
            // Остальные карточки добавляем в список других карточек (все карточки кроме первой)
            otherCards = cards.skip(1).toList();
          } else {
            // Если первая карточка не принята, она не показывается как "Вы",
            // но остальные карточки показываем (все карточки кроме первой)
            otherCards = cards.skip(1).toList();
          }
        } else {
          // Если нет токена, показываем все карточки
          otherCards = cards.toList();
        }

        final groupedCards = _groupCards(otherCards);
        debugPrint('Grouped cards: ${groupedCards.length} groups');
        debugPrint(
            'User card: ${userCard?.name} with status: ${userCard?.status}');
        debugPrint('Other cards count: ${otherCards.length}');

        return Column(
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
                if (entry.value.isNotEmpty) ...[
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
            ] else if (userCard == null) ...[
              const SizedBox(height: 100),
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
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) {
        debugPrint('Error state: $error');
        // Если ошибка 401, пытаемся все равно отобразить список других пользователей,
        // игнорируя ошибку для персональной карточки
        if (error.toString().contains('401')) {
          // Пытаемся повторно загрузить данные, исключая персональную карточку
          Future.microtask(() {
            if (mounted) {
              _resetPagination();
              ref.invalidate(communityCardsProvider);
            }
          });

          // Показываем загрузку пока обновляются данные
          if (cards.isEmpty) {
            return _buildSkeletonLoader();
          }

          // Если у нас уже есть какие-то карточки, отображаем их
          final groupedCards = _groupCards(cards);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок для других участников
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

              // Отображаем доступные карточки
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
                  ...entry.value.map((user) => _CommunityUserCard(user: user)),
                ],
              ] else ...[
                const SizedBox(height: 100),
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

              const SizedBox(height: 24),
            ],
          );
        }

        final is500Error = error.toString().contains('500') ||
            error.toString().contains('Internal Server Error');

        return ErrorRefreshWidget(
          height: 300,
          onRefresh: () {
            Future.microtask(() async {
              try {
                _resetPagination();
                ref.invalidate(communityCardsProvider);
                ref.invalidate(communityCardProvider);
              } catch (e) {
                debugPrint('❌ Ошибка при обновлении сообщества: $e');
              }
            });
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

  Widget _buildSkeletonLoader() {
    // Skeleton loader теперь должен быть просто контентом, не включающим RefreshIndicator
    return SizedBox(
      height: 500, // Фиксированная высота для скелетона
      child: Column(
        children: [
          // Search bar and button skeletons are now outside this component

          // Группы пользователей skeleton
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
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
                      2, // Показываем по 2 карточки на группу в скелетоне
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
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
            ),
          ),
        ],
      ),
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
