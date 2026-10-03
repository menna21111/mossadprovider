import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/mosaed_colors.dart';

class MosaedIconCircle extends StatelessWidget {
  const MosaedIconCircle({
    super.key,
    this.icon,
    this.svgAsset,
    this.size = 36,
    this.iconSize = 18,
    this.radius,
    this.iconColor = MosaedColors.brand,
  }) : assert(icon != null || svgAsset != null);

  final IconData? icon;
  final String? svgAsset;
  final double size;
  final double iconSize;
  final double? radius;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: MosaedColors.brandTransparent,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            radius == null ? null : BorderRadius.circular(radius!.r),
      ),
      alignment: Alignment.center,
      child: svgAsset != null
          ? SvgPicture.asset(
              svgAsset!,
              width: iconSize.sp,
              height: iconSize.sp,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : Icon(icon, size: iconSize.sp, color: iconColor),
    );
  }
}
