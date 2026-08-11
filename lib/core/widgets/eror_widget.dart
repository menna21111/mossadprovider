import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/color_manager.dart';
import '../constants/styles_manager.dart';

class ErorWidget extends StatelessWidget {
  const ErorWidget({super.key, required this.message, required this.onpressed});
  final String message;
  final Function() onpressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: getMediumStyle2(fontSize: 14.sp, color: ColorManager.red),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: onpressed,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: ColorManager.gold,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Retry',
                style: getMediumStyle2(
                  fontSize: 14.sp,
                  color: ColorManager.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
