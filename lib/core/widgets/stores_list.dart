import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/stores/stores_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class StoresList extends ConsumerStatefulWidget {
  final String mallId;
  final String? categoryId;
  final String? searchQuery;
  final EdgeInsets? padding;

  const StoresList({
    super.key,
    required this.mallId,
    this.categoryId,
    this.searchQuery,
    this.padding,
  });

  @override
  ConsumerState<StoresList> createState() => _StoresListState();
}

class _StoresListState extends ConsumerState<StoresList> {
  bool _isLoadingMore = false;
  String? _previousMallId;

  @override
  void didUpdateWidget(StoresList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if any of the parameters changed
    if (oldWidget.mallId != widget.mallId ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.searchQuery != widget.searchQuery) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Always load stores, even if mallId is empty (for "All Malls" option)
          ref.read(storesProvider(widget.mallId).notifier).loadInitialStores(
                categoryId: widget.categoryId,
                searchQuery: widget.searchQuery,
              );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _previousMallId = widget.mallId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Always load stores, even if mallId is empty (for "All Malls" option)
        ref.read(storesProvider(widget.mallId).notifier).loadInitialStores(
              categoryId: widget.categoryId,
              searchQuery: widget.searchQuery,
            );
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupStoresByLetter(
      List<Map<String, dynamic>> stores) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var store in stores) {
      final name = store['name'] as String? ?? '';
      if (name.isEmpty) continue;

      final firstLetter = name[0].toUpperCase();
      grouped.putIfAbsent(firstLetter, () => []);
      grouped[firstLetter]!.add(store);
    }

    // Sort stores within each group
    for (var stores in grouped.values) {
      stores.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    }

    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    // We'll always load stores, even if mallId is empty (for "All Malls" option)
    final storesAsync = ref.watch(storesProvider(widget.mallId));
    final hasMorePages =
        ref.read(storesProvider(widget.mallId).notifier).hasMorePages;

    return storesAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
      data: (stores) => _buildStoresList(stores, hasMorePages),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: _buildSkeletonLoader(),
    );
  }

  Widget _buildErrorState(Object error) {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppLength.xs,
            vertical: AppLength.xs,
          ),
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDDDD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF5252), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE53935),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'stories.error.loading'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(storesProvider(widget.mallId).notifier)
                      .loadInitialStores(
                        categoryId: widget.categoryId,
                        searchQuery: widget.searchQuery,
                        forceRefresh: true,
                      );
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'common.refresh'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoresList(
      List<Map<String, dynamic>> stores, bool hasMorePages) {
    if (stores.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text('stores.empty'.tr()),
        ),
      );
    }

    // Group stores by first letter
    final Map<String, List<Map<String, dynamic>>> storesByLetter = {};
    for (final store in stores) {
      final name = store['name'] as String;
      if (name.isNotEmpty) {
        final firstLetter = name[0].toUpperCase();
        if (!storesByLetter.containsKey(firstLetter)) {
          storesByLetter[firstLetter] = [];
        }
        storesByLetter[firstLetter]!.add(store);
      }
    }

    // Sort letters alphabetically
    final letters = storesByLetter.keys.toList()..sort();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Check if we need to load more when approaching the end
            if (index == letters.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (hasMorePages && !_isLoadingMore) {
                  _loadMoreStores();
                }
              });
            }

            if (index < letters.length) {
              final letter = letters[index];
              final storesForLetter = storesByLetter[letter]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 16),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey2,
                      ),
                    ),
                  ),
                  ...storesForLetter.map((store) => _buildStoreItem(store)),
                ],
              );
            } else {
              // Loading indicator at the end
              return _isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox.shrink();
            }
          },
          childCount: letters.length + (hasMorePages ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First letter group
          _buildSkeletonLetterGroup(),
          const SizedBox(height: 24),
          // Second letter group
          _buildSkeletonLetterGroup(),
          const SizedBox(height: 24),
          // Third letter group
          _buildSkeletonLetterGroup(),
        ],
      ),
    );
  }

  Widget _buildSkeletonLetterGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Letter header
        Shimmer.fromColors(
          baseColor: Colors.grey[100]!,
          highlightColor: Colors.grey[300]!,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Store items
        ...List.generate(3, (index) => _buildSkeletonStoreItem()),
      ],
    );
  }

  Widget _buildSkeletonStoreItem() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: 150,
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
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Divider(height: 1),
        ),
      ],
    );
  }

  Widget _buildStoreItem(Map<String, dynamic> store) {
    final shortDescription = store['short_description'] as String?;

    return Column(
      children: [
        InkWell(
          onTap: () {
            context.pushNamed(
              'store_details',
              pathParameters: {'id': store['id'].toString()},
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 0,
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (shortDescription != null &&
                    shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shortDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _loadMoreStores() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Always load more stores, even if mallId is empty (for "All Malls" option)
    ref
        .read(storesProvider(widget.mallId).notifier)
        .loadMoreStores(
          categoryId: widget.categoryId,
          searchQuery: widget.searchQuery,
        )
        .then((_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }
}
