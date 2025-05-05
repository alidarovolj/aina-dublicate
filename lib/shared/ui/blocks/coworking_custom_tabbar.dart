import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class CoworkingCustomTabBar extends StatefulWidget {
  final TabController tabController;

  const CoworkingCustomTabBar({
    super.key,
    required this.tabController,
  });

  @override
  State<CoworkingCustomTabBar> createState() => _CoworkingCustomTabBarState();
}

class _CoworkingCustomTabBarState extends State<CoworkingCustomTabBar> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.tabController.index;
    widget.tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.indexIsChanging ||
        widget.tabController.index != currentIndex) {
      if (mounted) {
        setState(() {
          currentIndex = widget.tabController.index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Обновляем локальный индекс при каждом рендере, чтобы быть уверенными,
    // что мы показываем правильную активную вкладку
    currentIndex = widget.tabController.index;

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
          controller: widget.tabController,
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
                    currentIndex == 0 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 1 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 2 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 3 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 4 ? AppColors.white : AppColors.darkGrey,
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
