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

    if (oldWidget.mallId != widget.mallId ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.searchQuery != widget.searchQuery) {
      // print(
      // 'Mall ID, Category ID or Search Query changed. Reloading stores...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(storesProvider(widget.mallId).notifier).loadInitialStores(
              categoryId: widget.categoryId,
              searchQuery: widget.searchQuery,
            );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _previousMallId = widget.mallId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storesProvider(widget.mallId).notifier).loadInitialStores(
            categoryId: widget.categoryId,
            searchQuery: widget.searchQuery,
          );
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

  Future<void> _loadMoreStores() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await ref.read(storesProvider(widget.mallId).notifier).loadMoreStores(
          categoryId: widget.categoryId,
          searchQuery: widget.searchQuery,
        );
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider(widget.mallId));
    final hasMorePages =
        ref.read(storesProvider(widget.mallId).notifier).hasMorePages;

    return storesAsync.when(
      data: (stores) {
        if (stores.isEmpty) {
          return Center(
            child: Text('stores.no_stores'.tr()),
          );
        }
        final groupedStores = _groupStoresByLetter(stores);
        final letters = groupedStores.keys.toList();

        return SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Check if we need to load more
                if (index == letters.length - 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (hasMorePages && !_isLoadingMore) {
                      _loadMoreStores();
                    }
                  });
                }

                if (index >= letters.length) {
                  if (_isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return null;
                }

                final letter = letters[index];
                final letterStores = groupedStores[letter]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey2,
                        ),
                      ),
                    ),
                    ...letterStores.map((store) => StoreListItem(store: store)),
                  ],
                );
              },
              childCount: letters.length + (hasMorePages ? 1 : 0),
            ),
          ),
        );
      },
      loading: () => Center(
        child: Text('stores.loading'.tr()),
      ),
      error: (error, stack) => Center(
        child: Text('stores.error'.tr(args: [error.toString()])),
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
}

class StoreListItem extends StatelessWidget {
  final Map<String, dynamic> store;

  const StoreListItem({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
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
              horizontal: 16,
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
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}
