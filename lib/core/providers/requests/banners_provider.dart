import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/slides.dart';
import 'package:aina_flutter/core/providers/requests/banners/list.dart';

class BannersProvider extends StateNotifier<AsyncValue<List<Slide>>> {
  BannersProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchBanners();
  }

  final RequestCodeService _listService;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchBanners({bool forceRefresh = false}) async {
    if (!_mounted) return;

    if (forceRefresh) {
      if (!_mounted) return;
      state = const AsyncValue.loading();
    }

    try {
      // print('Fetching banners...');
      final response = await _listService.banners();

      if (!_mounted) return;

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch banners');
      }

      final List<Slide> banners = (response.data['data'] as List)
          .map((json) => Slide.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!_mounted) return;
      state = AsyncValue.data(banners);
      // print('Banners fetched successfully.');
    } catch (error, stackTrace) {
      // print('Error fetching banners: $error');
      if (!_mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final bannersProvider =
    StateNotifierProvider.autoDispose<BannersProvider, AsyncValue<List<Slide>>>(
        (ref) {
  return BannersProvider(ref.read(requestCodeProvider));
});
