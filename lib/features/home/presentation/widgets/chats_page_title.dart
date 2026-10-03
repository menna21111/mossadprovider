import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class ChatsPageTitle extends StatelessWidget {
  const ChatsPageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getBoldStyle(
              fontSize: 16.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: MosaedColors.border,
        ),
      ],
    );
  }
}
