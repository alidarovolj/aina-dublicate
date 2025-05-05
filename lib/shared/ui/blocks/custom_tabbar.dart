import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class CustomTabBar extends StatefulWidget {
  final TabController tabController;

  const CustomTabBar({super.key, required this.tabController});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
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
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          controller: widget.tabController,
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
                    currentIndex == 0 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 1 ? AppColors.white : AppColors.darkGrey,
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
                    currentIndex == 2 ? AppColors.white : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/tabbar_store.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'main_tabs.shops'.tr()),
            Tab(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    currentIndex == 3 ? AppColors.white : AppColors.darkGrey,
                    BlendMode.srcIn,
                  ),
                  child: SvgPicture.asset(
                    "lib/app/assets/icons/profile.svg",
                    width: 28,
                    height: 28,
                  ),
                ),
                text: 'main_tabs.profile'.tr()),
          ],
        ),
      ),
    );
  }
}
