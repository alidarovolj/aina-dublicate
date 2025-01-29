import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoworkingCustomTabBar extends StatelessWidget {
  final TabController tabController;

  const CoworkingCustomTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 1,
            color: const Color(0xFFEEEEEE),
          ),
          TabBar(
            controller: tabController,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.grey2,
            indicatorColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
                  text: "Promenade"),
              Tab(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      tabController.index == 0
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
                  text: "Сообщество"),
              Tab(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      tabController.index == 0
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
                  text: "Услуги"),
              Tab(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      tabController.index == 0
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
                  text: "Брони"),
              Tab(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      tabController.index == 0
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
        ],
      ),
    );
  }
}
