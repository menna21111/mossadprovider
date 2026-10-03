import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class ChatsErrorState extends StatelessWidget {
  const ChatsErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      color: MosaedColors.brand,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Icon(
            Icons.wifi_off_rounded,
            size: 48.sp,
            color: MosaedColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            error,
            textAlign: TextAlign.center,
            style: getRegularStyle(
              fontSize: 14.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('mosaedRetry'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
