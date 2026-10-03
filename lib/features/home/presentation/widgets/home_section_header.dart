import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: getMediumStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'mosaedViewAll'.tr(),
                style: getRegularStyle(fontSize: 13.sp, color: MosaedColors.brand),
              ),
            ),
        ],
      ),
    );
  }
}

