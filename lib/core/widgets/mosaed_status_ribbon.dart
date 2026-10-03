import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import '../constants/styles_manager.dart';

class MosaedStatusRibbon extends StatelessWidget {
  const MosaedStatusRibbon({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      end: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: MosaedColors.brandTransparent,
          borderRadius: BorderRadiusDirectional.only(
            bottomStart: Radius.circular(10.r),
          ),
        ),
        child: Text(
          label,
          style: getMediumStyle(fontSize: 10.sp, color: MosaedColors.brand),
        ),
      ),
    );
  }
}
