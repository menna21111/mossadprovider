import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class HomeEmptyStrip extends StatelessWidget {
  const HomeEmptyStrip({
    super.key,
    required this.message,
    this.image,
  });

  final String message;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null) ...[
              Image.asset(
                image!,
                width: 140.w,
                height: 110.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10.h),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: getBoldStyle(
                fontSize: 15.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
