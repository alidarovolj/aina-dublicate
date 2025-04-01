import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/features/coworking/model/models/coworking_user_data.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';

final coworkingUserProvider =
    FutureProvider.family<CoworkingUserData, int>((ref, coworkingId) async {
  try {
    // TODO: Replace with actual API endpoint
    final response =
        await ApiClient().dio.get('/api/coworking/$coworkingId/user-data');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch coworking user data');
    }

    return CoworkingUserData.fromJson(response.data['data']);
  } on DioException catch (e) {
    throw Exception('Error fetching coworking user data: ${e.message}');
  }
});

final coworkingUserServiceProvider =
    Provider((ref) => CoworkingUserService(ApiClient().dio));

class CoworkingUserService {
  final Dio _dio;

  CoworkingUserService(this._dio);

  Future<bool> updateUserData(int coworkingId, CoworkingUserData data) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _dio.put(
        '/api/coworking/$coworkingId/user-data',
        data: data.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
