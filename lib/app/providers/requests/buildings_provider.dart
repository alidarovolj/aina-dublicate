import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/building.dart';
import 'package:aina_flutter/app/providers/requests/buildings/list.dart';

class BuildingsProvider
    extends StateNotifier<AsyncValue<Map<String, List<Building>>>> {
  BuildingsProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchBuildings();
  }

  final RequestBuildingsService _listService;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchBuildings() async {
    if (!_mounted) return;

    try {
      final response = await _listService.buildings();

      if (!_mounted) return;

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch buildings');
      }

      final List<Building> allBuildings = (response.data['data'] as List)
          .map((json) => Building.fromJson(json))
          .toList();

      // Filter buildings by type
      final Map<String, List<Building>> filteredBuildings = {
        'mall': allBuildings.where((b) => b.type == 'mall').toList(),
        'coworking': allBuildings.where((b) => b.type == 'coworking').toList(),
      };

      if (!_mounted) return;
      state = AsyncValue.data(filteredBuildings);
    } catch (error, stackTrace) {
      if (!_mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final buildingsProvider = StateNotifierProvider<BuildingsProvider,
    AsyncValue<Map<String, List<Building>>>>(
  (ref) => BuildingsProvider(ref.read(requestBuildingsProvider)),
);
