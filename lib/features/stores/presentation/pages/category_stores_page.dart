import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/features/stores/data/providers/category_stores_provider.dart';
import 'package:aina_flutter/core/widgets/category_card.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoryStoresPage extends ConsumerStatefulWidget {
  final String buildingId;
  final String categoryId;
  final String title;

  const CategoryStoresPage({
    super.key,
    required this.buildingId,
    required this.categoryId,
    required this.title,
  });

  @override
  ConsumerState<CategoryStoresPage> createState() => _CategoryStoresPageState();
}

class _CategoryStoresPageState extends ConsumerState<CategoryStoresPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(
        categoryStoresProvider(
                (buildingId: widget.buildingId, categoryId: widget.categoryId))
            .notifier,
      );
      if (notifier.hasMorePages) {
        notifier.loadMoreStores();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(categoryStoresProvider(
        (buildingId: widget.buildingId, categoryId: widget.categoryId)));
    final buildingsAsync = ref.watch(buildingsProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                margin: const EdgeInsets.only(top: 64),
                child: storesAsync.when(
                  data: (stores) => stores.isEmpty
                      ? const Center(
                          child: Text('Нет магазинов в данной категории'),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: stores.length,
                          itemBuilder: (context, index) {
                            final store = stores[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CategoryCard(
                                title: store.name,
                                imageUrl: store.previewImage?.url,
                                subtitle: store.shortDescription,
                                height: 180,
                                onTap: () {
                                  context.pushNamed(
                                    'store_details',
                                    pathParameters: {'id': store.id.toString()},
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                ),
              ),
              buildingsAsync.when(
                data: (buildings) {
                  final mall = (buildings['mall'] ?? []).firstWhere(
                    (building) => building.id.toString() == widget.buildingId,
                    orElse: () => throw Exception('Mall not found'),
                  );
                  return CustomHeader(
                    title: '${widget.title} в ${mall.name}',
                    type: HeaderType.pop,
                  );
                },
                loading: () => const CustomHeader(
                  title: 'Загрузка...',
                  type: HeaderType.pop,
                ),
                error: (_, __) => CustomHeader(
                  title: widget.title,
                  type: HeaderType.pop,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
