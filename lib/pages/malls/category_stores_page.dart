import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/features/stores/data/providers/category_stores_provider.dart';
import 'package:aina_flutter/widgets/category_card.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/types/building.dart';

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
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isLoadingMore) {
      return; // Предотвращаем множественные вызовы во время загрузки
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(
        categoryStoresProvider(
                (buildingId: widget.buildingId, categoryId: widget.categoryId))
            .notifier,
      );
      if (notifier.hasMorePages) {
        setState(() {
          _isLoadingMore = true;
        });

        notifier.loadMoreStores().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
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
                      ? Center(
                          child: Text('stores.no_stores'.tr()),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: stores.length,
                                itemBuilder: (context, index) {
                                  final store = stores[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CategoryCard(
                                      title: store.name,
                                      imageUrl: _cleanImageUrl(
                                          store.previewImage?.url),
                                      subtitle: store.shortDescription,
                                      height: 180,
                                      onTap: () {
                                        context.pushNamed(
                                          'store_details',
                                          pathParameters: {
                                            'id': store.id.toString()
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_isLoadingMore)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                ),
              ),
              CustomHeader(
                title: context.locale.languageCode == 'kk'
                    ? 'stores.category_title'.tr(args: [
                        buildingsAsync.when(
                          data: (buildings) {
                            final malls = buildings['mall'] ?? [];
                            final mall = malls.firstWhere(
                              (m) => m.id.toString() == widget.buildingId,
                              orElse: () => malls.isNotEmpty
                                  ? malls.first
                                  : Building(
                                      id: 0,
                                      name: '',
                                      type: '',
                                      phone: '',
                                      latitude: '',
                                      longitude: '',
                                      description: '',
                                      workingHours: '',
                                      address: '',
                                      createdAt: '',
                                      previewImage: PreviewImage(
                                        id: 0,
                                        uuid: '',
                                        url: '',
                                        urlOriginal: '',
                                        orderColumn: 0,
                                        collectionName: '',
                                      ),
                                      images: [],
                                    ),
                            );
                            return mall.name;
                          },
                          loading: () => '',
                          error: (_, __) => '',
                        ),
                        widget.title,
                      ])
                    : 'stores.category_title'.tr(args: [
                        widget.title,
                        buildingsAsync.when(
                          data: (buildings) {
                            final malls = buildings['mall'] ?? [];
                            final mall = malls.firstWhere(
                              (m) => m.id.toString() == widget.buildingId,
                              orElse: () => malls.isNotEmpty
                                  ? malls.first
                                  : Building(
                                      id: 0,
                                      name: '',
                                      type: '',
                                      phone: '',
                                      latitude: '',
                                      longitude: '',
                                      description: '',
                                      workingHours: '',
                                      address: '',
                                      createdAt: '',
                                      previewImage: PreviewImage(
                                        id: 0,
                                        uuid: '',
                                        url: '',
                                        urlOriginal: '',
                                        orderColumn: 0,
                                        collectionName: '',
                                      ),
                                      images: [],
                                    ),
                            );
                            return mall.name;
                          },
                          loading: () => '',
                          error: (_, __) => '',
                        ),
                      ]),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
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

  String _cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Проверяем на наличие HTTP ошибок в URL
    if (url.contains('HTTP') ||
        url.toLowerCase().contains('error') ||
        !url.startsWith('http')) {
      return ''; // Возвращаем пустую строку для невалидных URL
    }

    // Проверяем на наличие специфических ошибок в URL
    if (url.contains('404') ||
        url.contains('500') ||
        url.contains('403') ||
        url.contains('not found') ||
        url.contains('undefined')) {
      return ''; // Возвращаем пустую строку для URL с ошибками
    }

    // Если URL содержит специальные символы или пробелы, кодируем их
    if (url.contains(' ') ||
        url.contains('%') ||
        url.contains('?') ||
        url.contains('&')) {
      try {
        // Пытаемся закодировать URL
        final Uri uri = Uri.parse(url);
        return uri.toString();
      } catch (e) {
        // Если не удалось закодировать, возвращаем пустую строку
        return '';
      }
    }

    return url;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
