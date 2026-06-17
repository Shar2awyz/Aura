import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// Exposed so the SliverPersistentHeaderDelegate can use the exact same value.
const double kProfileTabBarHeight = 50.0;

class ProfileTabBar extends StatelessWidget {
  final TabController controller;

  const ProfileTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kProfileTabBarHeight,
      color: AppColors.darkBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.darkBorder,
          ),
          TabBar(
            controller: controller,
            indicatorColor: Colors.white,
            indicatorWeight: 1.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSubtleOnDark,
            padding: EdgeInsets.zero,
            tabs: const [
              Tab(icon: Icon(Icons.grid_view_rounded, size: 22)),
              Tab(icon: Icon(Icons.video_library_rounded, size: 22)),
              Tab(icon: Icon(Icons.bookmark_border_rounded, size: 22)),
              Tab(icon: Icon(Icons.person_pin_circle_outlined, size: 22)),
            ],
          ),
        ],
      ),
    );
  }
}
