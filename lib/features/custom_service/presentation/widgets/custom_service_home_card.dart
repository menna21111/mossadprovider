import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class CustomServiceHomeCard extends StatelessWidget {
  const CustomServiceHomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: MosaedColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: MosaedColors.surfaceContainerLow),
          boxShadow: MosaedColors.softShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: MosaedColors.primaryFixed,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.person_pin_rounded,
                      color: MosaedColors.primary,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mosaedCustomServiceHomeDesc'.tr(),
                          style: getRegularStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: MosaedColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              'mosaedCustomProblemHint'.tr(),
                              style: getRegularStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: MosaedColors.surfaceContainerLow),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.image_outlined,
                    label: 'mosaedPhoto'.tr(),
                    onTap: onTap,
                  ),
                  SizedBox(width: 8.w),
                  _ActionChip(
                    icon: Icons.location_on_outlined,
                    label: 'mosaedLocationShort'.tr(),
                    onTap: onTap,
                  ),
                  const Spacer(),
                  Material(
                    color: MosaedColors.primary,
                    borderRadius: BorderRadius.circular(14.r),
                    elevation: 4,
                    shadowColor: MosaedColors.primary.withValues(alpha: 0.25),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(14.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        child: Text(
                          'mosaedPublishNow'.tr(),
                          style: getBoldStyle(
                            fontSize: 13.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: MosaedColors.textSecondary),
            SizedBox(width: 4.w),
            Text(
              label,
              style: getMediumStyle(
                fontSize: 12.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
