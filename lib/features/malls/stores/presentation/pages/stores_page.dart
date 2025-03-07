import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/store_categories_list.dart';
import 'package:aina_flutter/core/widgets/stores_list.dart';
import 'package:aina_flutter/core/widgets/mall_selector.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

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

    // When "All Malls" is selected, selectedMallId will be null
    // In this case, we should pass an empty string to ensure no building_id is sent in the API request
    final String effectiveMallId = selectedMallId ?? "";

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
                              decoration: InputDecoration(
                                hintText: 'stores.search_placeholder'.tr(),
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
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
                            child: MallSelector(
                              selectedMallId: selectedMallId,
                              isFromMall: isFromMall,
                              onChanged: (String? newValue) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      selectedMallId = newValue;
                                    });
                                  }
                                });
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
