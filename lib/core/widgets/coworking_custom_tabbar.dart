import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
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
          tabs: [
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 0
                        ? AppColors.white
                        : AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/core/assets/icons/tabbar_home.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.promenade'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 1
                        ? AppColors.white
                        : AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/core/assets/icons/tabbar_community.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.community'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 2
                        ? AppColors.white
                        : AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/core/assets/icons/tabbar_services.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.services'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 3
                        ? AppColors.white
                        : AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/core/assets/icons/tabbar_book.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'coworking_tabs.bookings'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 4
                        ? AppColors.white
                        : AppColors.textDarkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/core/assets/icons/profile.svg",
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
