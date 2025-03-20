import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/requests/news_provider.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/core/types/news_params.dart';
import 'package:easy_localization/easy_localization.dart';

class NewsListPage extends ConsumerStatefulWidget {
  final String? buildingId;

  const NewsListPage({
    super.key,
    this.buildingId,
  });

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      // Загрузка следующей страницы происходит автоматически через провайдер
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildNewsCard(dynamic newsItem) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'news_details',
          pathParameters: {'id': newsItem.id.toString()},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(newsItem.previewImage.url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (newsItem.building != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLength.xs,
                    vertical: AppLength.four,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    newsItem.building!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newsItem.title,
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newsItem.formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
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

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[100]!,
      highlightColor: Colors.grey[300]!,
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider(
      NewsParams(
        page: _currentPage,
        buildingId: widget.buildingId,
      ),
    ));

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppColors.appBg,
              margin: const EdgeInsets.only(top: 64),
              child: newsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppLength.xs),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildSkeletonLoader(),
                ),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (newsResponse) => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppLength.xs),
                  itemCount:
                      newsResponse.data.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < newsResponse.data.length) {
                      return _buildNewsCard(newsResponse.data[index]);
                    } else {
                      return _buildSkeletonLoader();
                    }
                  },
                ),
              ),
            ),
            CustomHeader(
              title: 'news.title'.tr(),
              type: HeaderType.pop,
            ),
          ],
        ),
      ),
    );
  }
}
