import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/update_notifier_provider.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateModal extends ConsumerWidget {
  const UpdateModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    UpdateNotifierState? updateState;
    try {
      updateState = ref.watch(updateNotifierProvider);
    } catch (e) {
      // Handle any errors that might occur when watching the provider
      return const SizedBox.shrink();
    }

    if (updateState == null || updateState.type == UpdateType.none) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'update.new_version'.tr(),
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: SvgPicture.asset(
                  'lib/app/assets/icons/upload.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'update.description'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'v${updateState.currentVersion} → v${updateState.newVersion}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'update.update'.tr(),
              isFullWidth: true,
              onPressed: () async {
                final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
                final url = isIOS
                    ? 'https://apps.apple.com/kz/app/aina/id6478210836'
                    : 'https://play.google.com/store/apps/details?id=kz.aina.android1';

                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
            if (updateState.type == UpdateType.minor) ...[
              const SizedBox(height: 12),
              CustomButton(
                onPressed: () {
                  try {
                    ref
                        .read(updateNotifierProvider.notifier)
                        .resetUpdateState();
                  } catch (e) {
                    debugPrint('Error resetting update state: $e');
                  }
                },
                label: 'update.skip'.tr(),
                textColor: Colors.red,
                type: ButtonType.normal,
                backgroundColor: Colors.white,
                isFullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
