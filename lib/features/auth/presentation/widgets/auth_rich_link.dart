import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

/// Centered "prefix + highlighted action" text link.
class AuthRichLink extends StatelessWidget {
  const AuthRichLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: getSemiBoldStyle(
            fontSize: 14.sp,
            color: MosaedColors.textPrimary,
          ),
          children: [
            TextSpan(text: '$prefix '),
            TextSpan(
              text: action,
              style: getBoldStyle(
                fontSize: 14.sp,
                color: MosaedColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
