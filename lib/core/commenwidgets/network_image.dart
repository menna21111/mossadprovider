import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/color_manager.dart';

class NetworkImages extends StatelessWidget {
  const NetworkImages({
    super.key,
    required this.imagepath,

    required this.height,
    this.width,
  });
  final String imagepath;

  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) {
    return Image.network(
      width: width,
      imagepath,
      height: height.h,
      fit: BoxFit.fill,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return SizedBox(
          height: height.h,
          width: width,
          child: Center(
            child: CircularProgressIndicator(color: ColorManager.primary),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height.h,
          width: width,
          child: Center(
            child: Icon(
              Icons.error_outline,
              color: ColorManager.primary,
              size: 40.sp,
            ),
          ),
        );
      },
    );
  }
}
