import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';

class MosaedLogo extends StatelessWidget {
  const MosaedLogo({
    super.key,
    this.width = 110,
    this.height,
    this.showTagline = false,
  });

  final double width;
  final double? height;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImageAssets.logo,
      width: width.w,
      height: height?.h,
      fit: BoxFit.contain,
    );
  }
}
