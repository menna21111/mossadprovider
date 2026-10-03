import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

/// Full-page empty illustration for أعمالي tabs.
class MyWorksEmptyState extends StatelessWidget {
  const MyWorksEmptyState({
    super.key,
    required this.image,
    required this.message,
  });

  final String image;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 80.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              children: [
                Image.asset(
                  image,
                  width: 220.w,
                  height: 200.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 24.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: getBoldStyle(
                    fontSize: 17.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
