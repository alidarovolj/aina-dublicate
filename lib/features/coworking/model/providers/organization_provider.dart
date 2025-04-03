import 'package:aina_flutter/app/providers/api_client_provider.dart';
import 'package:aina_flutter/features/coworking/model/organization.dart';
import 'package:aina_flutter/features/coworking/model/services/organization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationParams {
  final String buildingId;
  final int page;

  OrganizationParams({
    required this.buildingId,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationParams &&
          runtimeType == other.runtimeType &&
          buildingId == other.buildingId &&
          page == other.page;

  @override
  int get hashCode => buildingId.hashCode ^ page.hashCode;
}

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrganizationService(apiClient);
});

final organizationsProvider =
    FutureProvider.family<OrganizationsResponse, OrganizationParams>(
  (ref, params) async {
    final service = ref.watch(organizationServiceProvider);
    return service.getOrganizations(
      buildingId: params.buildingId,
      page: params.page,
    );
  },
);
