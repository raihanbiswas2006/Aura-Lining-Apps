import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'review_moderation_screen.dart';
import '../../promotions/presentation/coupon_list_screen.dart';

class ModerationPromosTabScreen extends StatefulWidget {
  const ModerationPromosTabScreen({super.key});

  @override
  State<ModerationPromosTabScreen> createState() => _ModerationPromosTabScreenState();
}

class _ModerationPromosTabScreenState extends State<ModerationPromosTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Moderation & Marketing'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryOlive,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryOlive,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Review Queue',
                ),
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  text: 'Coupon Codes',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReviewModerationScreen(),
          CouponListScreen(),
        ],
      ),
    );
  }
}
