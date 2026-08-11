import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({
    super.key,
    required this.titleKey,
    required this.bodyKey,
    this.bulletKeys = const [],
  });

  final String titleKey;
  final String bodyKey;
  final List<String> bulletKeys;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          titleKey.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: MosaedColors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: MosaedColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bodyKey.tr(),
                style: getRegularStyle(
                  fontSize: 15.sp,
                  color: MosaedColors.textPrimary,
                  height: 1.6,
                ),
              ),
              if (bulletKeys.isNotEmpty) ...[
                SizedBox(height: 16.h),
                ...bulletKeys.map(
                  (key) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: MosaedColors.primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            key.tr(),
                            style: getRegularStyle(
                              fontSize: 14.sp,
                              color: MosaedColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
