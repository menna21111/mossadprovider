import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../auth/presentation/widgets/mosaed_buttons.dart';

enum LocationPromptAction { currentLocation, manual, later }

/// Bottom-sheet: illustration + location method choices.
class LocationPromptSheet extends StatelessWidget {
  const LocationPromptSheet({super.key});

  /// Shows over the current page (addresses/home) with a dim translucent barrier.
  static Future<LocationPromptAction?> show(BuildContext context) {
    return showModalBottomSheet<LocationPromptAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => const LocationPromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MosaedColors.fieldBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 20.h),
              Image.asset(
                ImageAssets.chooseAddress,
                width: 220.w,
                height: 160.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16.h),
              Text(
                'mosaedSelectYourLocation'.tr(),
                textAlign: TextAlign.center,
                style: getBoldStyle(
                  fontSize: 20.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'mosaedSelectLocationMethod'.tr(),
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 24.h),
              MosaedPrimaryButton(
                text: 'mosaedUseCurrentLocation'.tr(),
                icon: Icons.my_location_rounded,
                onPressed: () => Navigator.pop(
                  context,
                  LocationPromptAction.currentLocation,
                ),
              ),
              SizedBox(height: 12.h),
              MosaedOutlineButton(
                text: 'mosaedEnterManually'.tr(),
                icon: Icons.edit_outlined,
                onPressed: () =>
                    Navigator.pop(context, LocationPromptAction.manual),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () =>
                    Navigator.pop(context, LocationPromptAction.later),
                child: Text(
                  'mosaedLater'.tr(),
                  style: getBoldStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
