import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;

  const CustomTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.black.withOpacity(0.1), // Цвет тени
            blurRadius: AppLength.xxs, // Радиус размытия
            spreadRadius: 1, // Радиус распространения
            offset: const Offset(
                0, 4), // Смещение тени (по горизонтали и вертикали)
          ),
        ],
      ),
      child: TabBar(
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
                      : AppColors.textDarkGrey,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  "lib/core/assets/icons/tabbar_home.svg",
                  width: 28,
                  height: 28,
                ),
              ),
              text: "Главная"),
          Tab(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  tabController.index == 1
                      ? AppColors.white
                      : AppColors.textDarkGrey,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  "lib/core/assets/icons/tabbar_offers.svg",
                  width: 28,
                  height: 28,
                ),
              ),
              text: "Акции"),
          Tab(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  tabController.index == 2
                      ? AppColors.white
                      : AppColors.textDarkGrey,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  "lib/core/assets/icons/tabbar_store.svg",
                  width: 28,
                  height: 28,
                ),
              ),
              text: "Магазины"),
          Tab(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  tabController.index == 3
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
              text: "Профиль"),
        ],
      ),
    );
  }
}
