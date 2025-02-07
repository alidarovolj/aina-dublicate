import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/building.dart';
import 'package:aina_flutter/core/providers/requests/buildings/list.dart';

class BuildingsProvider
    extends StateNotifier<AsyncValue<Map<String, List<Building>>>> {
  BuildingsProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchBuildings();
  }

  final RequestBuildingsService _listService;

  Future<void> fetchBuildings() async {
    try {
      // print('Fetching buildings...');
      final response = await _listService.buildings();

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

      state = AsyncValue.data(filteredBuildings);
      // print('Buildings fetched and filtered successfully.');
    } catch (error, stackTrace) {
      // print('Error fetching buildings: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final buildingsProvider = StateNotifierProvider<BuildingsProvider,
    AsyncValue<Map<String, List<Building>>>>(
  (ref) => BuildingsProvider(ref.read(requestBuildingsProvider)),
);
