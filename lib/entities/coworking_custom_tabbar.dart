import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class CoworkingCustomTabBar extends StatelessWidget {
  final TabController tabController;

  const CoworkingCustomTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: const Border(
            top: BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: AppLength.xxs,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          controller: tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.grey2,
          indicatorColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: AppLength.xs,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppLength.xs,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.2,
          ),
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.only(top: 8),
          tabs: [
            Tab(
                height: 56,
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 0
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_home.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.promenade'.tr()),
            Tab(
                height: 56,
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 1
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_community.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.community'.tr()),
            Tab(
                height: 56,
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 2
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_services.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.services'.tr()),
            Tab(
                height: 56,
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 3
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/alert.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.bookings'.tr()),
            Tab(
                height: 56,
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 4
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/profile.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.profile'.tr()),
          ],
        ),
      ),
    );
  }
}
