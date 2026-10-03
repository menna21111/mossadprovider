import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import 'mosaed_logo.dart';

/// Logo + title + subtitle block used on auth screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoWidth = 110,
    this.logoHeight,
    this.showLogo = true,
  });

  final String title;
  final String subtitle;
  final double logoWidth;
  final double? logoHeight;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLogo) ...[
          SizedBox(
            width: logoWidth.w,
            height: (logoHeight ?? 72).h,
            child: MosaedLogo(
              width: logoWidth,
              height: logoHeight ?? 72,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: getBoldStyle(
            fontSize: 28.sp,
            color: MosaedColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: getRegularStyle(
            fontSize: 15.sp,
            color: MosaedColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
