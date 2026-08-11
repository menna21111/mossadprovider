import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/mosaed_colors.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Column(
      children: [
        _box(baseColor, highlightColor, height: 160.h, radius: 20.r),
        SizedBox(height: 16.h),
        _box(baseColor, highlightColor, height: 90.h, radius: 16.r),
        SizedBox(height: 16.h),
        _box(baseColor, highlightColor, height: 180.h, radius: 16.r),
      ],
    );
  }

  Widget _box(Color base, Color highlight, {required double height, required double radius}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: MosaedColors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
