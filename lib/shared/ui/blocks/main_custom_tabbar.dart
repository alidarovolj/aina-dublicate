import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class MainCustomTabBar extends StatelessWidget {
  final TabController tabController;

  const MainCustomTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          controller: tabController,
          indicatorColor: Colors.transparent,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.grey2,
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
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_home.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'main_tabs.home'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 1
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/sale.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'main_tabs.promotions'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 2
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
                text: 'bookings.title'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 3
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_coupon.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'tickets.title'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    tabController.index == 4
                        ? AppColors.white
                        : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/menu.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'main_tabs.menu'.tr()),
          ],
        ),
      ),
    );
  }
}
