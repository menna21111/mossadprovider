import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class MosaedLogo extends StatelessWidget {
  const MosaedLogo({
    super.key,
    this.width = 220,
    this.showTagline = false,
  });

  /// Logo width — image keeps aspect ratio (includes مساعد + Musa'id text).
  final double width;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          ImageAssets.logo,
          width: width.w,
          fit: BoxFit.contain,
        ),
        if (showTagline) ...[
          SizedBox(height: 8.h),
          Text(
            'مساعدك في أعمال الصيانة',
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
