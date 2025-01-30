import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/buildings_provider.dart';
import 'package:aina_flutter/core/types/building.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:easy_localization/easy_localization.dart';

class MallSelector extends ConsumerWidget {
  final String? selectedMallId;
  final bool isFromMall;
  final ValueChanged<String?> onChanged;

  const MallSelector({
    super.key,
    required this.selectedMallId,
    required this.isFromMall,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsState = ref.watch(buildingsProvider);

    return buildingsState.when(
      data: (buildings) {
        final malls = buildings['mall'] ?? [];

        // Debug print all malls
        // print('Available malls in dropdown:');
        for (var mall in malls) {
          // print('Mall ID: ${mall.id}, Name: ${mall.name}');
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('mall_selector.select_mall'.tr()),
              value: selectedMallId,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('mall_selector.all_malls'.tr()),
                ),
                ...malls.map((Building mall) {
                  return DropdownMenuItem<String>(
                    value: mall.id.toString(),
                    child: Text(mall.name),
                  );
                }),
              ],
              onChanged: onChanged,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('mall_selector.error'.tr(args: [error.toString()])),
      ),
    );
  }
}
