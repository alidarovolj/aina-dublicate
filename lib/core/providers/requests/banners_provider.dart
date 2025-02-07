import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/slides.dart';
import 'package:aina_flutter/core/providers/requests/banners/list.dart';

class BannersProvider extends StateNotifier<AsyncValue<List<Slide>>> {
  BannersProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchBanners();
  }

  final RequestCodeService _listService;

  Future<void> fetchBanners() async {
    try {
      // print('Fetching banners...');
      final response = await _listService.banners();

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch banners');
      }

      final List<Slide> banners = (response.data['data'] as List)
          .map((json) => Slide.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(banners);
      // print('Banners fetched successfully.');
    } catch (error, stackTrace) {
      // print('Error fetching banners: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final bannersProvider =
    StateNotifierProvider<BannersProvider, AsyncValue<List<Slide>>>(
  (ref) => BannersProvider(ref.read(requestCodeProvider)),
);
