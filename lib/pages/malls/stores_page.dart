import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/entities/store_categories_list.dart';
import 'package:aina_flutter/entities/stores_list.dart';
import 'package:aina_flutter/widgets/custom_dropdown.dart';
import 'package:aina_flutter/app/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/shared/types/building.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';

class StoresPage extends ConsumerStatefulWidget {
  final int mallId;

  const StoresPage({
    super.key,
    required this.mallId,
  });

  @override
  ConsumerState<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends ConsumerState<StoresPage> {
  final ScrollController _scrollController = ScrollController();
  String? selectedMallId;
  String? selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.mallId != 0) {
      selectedMallId = widget.mallId.toString();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get category from query parameters if available
    final location = GoRouterState.of(context).uri.toString();
    final categoryFromQuery = location.contains('category=')
        ? Uri.parse(location).queryParameters['category']
        : null;

    if (categoryFromQuery != null) {
      setState(() {
        selectedCategoryId = categoryFromQuery;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFromMall = widget.mallId != 0;
    final String effectiveMallId = selectedMallId ?? "";
    final buildingsState = ref.watch(buildingsProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.appBg,
                margin: const EdgeInsets.only(top: 64),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'stores.search_placeholder'.tr(),
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.darkGrey,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.grey2,
                                  size: 24,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              right: 12.0,
                              top: 12,
                            ),
                            child: buildingsState.when(
                              loading: () => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey[100]!,
                                  highlightColor: Colors.grey[300]!,
                                  child: Container(
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              error: (error, stack) => Center(
                                child: Text('mall_selector.error'
                                    .tr(args: [error.toString()])),
                              ),
                              data: (buildings) {
                                final malls = buildings['mall'] ?? [];
                                final allMalls = [
                                  Building(
                                    id: 0,
                                    name: 'mall_selector.all_malls'.tr(),
                                    type: 'mall',
                                    previewImage: PreviewImage(
                                      id: 0,
                                      uuid: '',
                                      url: '',
                                      urlOriginal: '',
                                      orderColumn: 0,
                                      collectionName: '',
                                    ),
                                    phone: '',
                                    latitude: '',
                                    longitude: '',
                                    description: '',
                                    workingHours: '',
                                    address: '',
                                    createdAt: '',
                                    images: [],
                                  ),
                                  ...malls,
                                ];

                                return CustomDropdown<Building>(
                                  items: allMalls,
                                  value: allMalls.firstWhere(
                                    (mall) =>
                                        mall.id.toString() == selectedMallId,
                                    orElse: () => allMalls.first,
                                  ),
                                  labelBuilder: (mall) => mall.name,
                                  onChanged: (mall) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          selectedMallId = mall.id == 0
                                              ? null
                                              : mall.id.toString();
                                        });
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    StoreCategoriesList(
                      mallId: effectiveMallId,
                      onCategorySelected: (categoryId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              selectedCategoryId = categoryId;
                            });
                          }
                        });
                      },
                      useRouting: false,
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                    StoresList(
                      mallId: effectiveMallId,
                      categoryId: selectedCategoryId,
                      searchQuery: _searchQuery,
                    ),
                  ],
                ),
              ),
              CustomHeader(
                title: 'stores.title'.tr(),
                type: isFromMall ? HeaderType.close : HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
