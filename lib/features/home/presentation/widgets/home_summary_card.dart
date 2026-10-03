import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
     
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
       
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Row(
            children: [Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w,vertical: 6.h),
              decoration: BoxDecoration(
                color: MosaedColors.brand.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(icon, height: 20.h, width: 20.w),
            ),
              SizedBox(width: 8.w),
            Expanded(child:  Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: getMediumStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    value,
                       textAlign: TextAlign.center,
                    style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.brand),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                       textAlign: TextAlign.center,
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textHint,
                    ),
                  ),
                ],
              ),)
            ],
          ),
        ),
      ),
    );
  }
}

