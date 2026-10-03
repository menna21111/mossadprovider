import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import 'home_summary_card.dart';

class HomeSummarySection extends StatelessWidget {
  const HomeSummarySection({
    super.key,
    required this.nearbyCount,
    required this.pendingOffersCount,
    required this.activeJobsCount,
    this.onOpenRequests,
    this.onOpenOffers,
    this.onOpenTasks,
  });

  final int nearbyCount;
  final int pendingOffersCount;
  final int activeJobsCount;
  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenOffers;
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 20.h, 10.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'mosaedQuickSummary'.tr(),
            style: getMediumStyle(
              fontSize: 16.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: HomeSummaryCard(
                  title: 'mosaedNearbyOpportunities'.tr(),
                  value: '$nearbyCount',
                  subtitle: 'mosaedNewCount'.tr(),
                  icon: 'assets/images/user-add-01.svg',
                  onTap: onOpenRequests,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: HomeSummaryCard(
                  title: 'mosaedWaitingOffers'.tr(),
                  value: '$pendingOffersCount',
                  subtitle: 'mosaedFromClients'.tr(),
                  icon: 'assets/images/mail-01.svg',
                  onTap: onOpenOffers,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: HomeSummaryCard(
                  title: 'mosaedActiveJobs'.tr(),
                  value: '$activeJobsCount',
                  subtitle: 'mosaedInProgress'.tr(),
                  icon: 'assets/images/activeworksicon.svg',
                  onTap: onOpenTasks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
