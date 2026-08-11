import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/color_manager.dart';
import '../constants/styles_manager.dart';

class Eror extends StatelessWidget {
  const Eror({
    super.key,
    required this.hieght,
    required this.message,
    this.onRetry,
  });
  final double hieght;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * hieght,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            Text(
              message,
              style: getMediumStyle(
                fontSize: 14.sp,
                color: ColorManager.primary,
              ),
            ),
            SizedBox(height: 20.h),
            onRetry != null
                ? ElevatedButton(
                  onPressed: onRetry!,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 8.h,
                    ),
                    backgroundColor: ColorManager.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: getMediumStyle(
                      fontSize: 14.sp,
                      color: ColorManager.white,
                    ),
                  ),
                )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key, required this.hieght});
  final double hieght;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * hieght,
      child: Center(
        child: CircularProgressIndicator(color: ColorManager.primary),
      ),
    );
  }
}
