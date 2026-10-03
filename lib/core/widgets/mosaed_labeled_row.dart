import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import '../constants/styles_manager.dart';
import 'mosaed_icon_circle.dart';

class MosaedLabeledRow extends StatelessWidget {
  const MosaedLabeledRow({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.svgAsset,
    this.circleSize = 36,
    this.verticalPadding = 12,
  }) : assert(icon != null || svgAsset != null);

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final Widget child;
  final double circleSize;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosaedIconCircle(
            icon: icon,
            svgAsset: svgAsset,
            size: circleSize,
            radius: 10,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getBoldStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.brand,
                  ),
                ),
                SizedBox(height: 6.h),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MosaedFieldDivider extends StatelessWidget {
  const MosaedFieldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: const Divider(height: 1, thickness: 1, color: MosaedColors.fieldBorder),
    );
  }
}
