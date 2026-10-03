import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class AddressAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AddressAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.showDivider = false,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final bool showDivider;
  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(56.h + (showDivider ? 1 : 0));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: MosaedColors.surfaceWhite,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56.h,
                child: NavigationToolbar(
                  leading: showBack
                      ? IconButton(
                          onPressed:
                              onBack ?? () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        )
                      : null,
                  middle: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getBoldStyle(
                      fontSize: 16.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  trailing: actions == null || actions!.isEmpty
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        ),
                ),
              ),
              if (showDivider)
                Container(
                  height: 1,
                  width: double.infinity,
                  color: MosaedColors.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MosaedPageTitle extends StatelessWidget {
  const MosaedPageTitle(this.title, {super.key, this.showDivider = false});

  final String title;
  final bool showDivider;

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
        if (showDivider)
          Container(
            height: 1,
            width: double.infinity,
            color: MosaedColors.border,
          ),
      ],
    );
  }
}

class AddressFormIntro extends StatelessWidget {
  const AddressFormIntro({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: getBoldStyle(
            fontSize: 16.sp,
            color: MosaedColors.textPrimary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          textAlign: TextAlign.start,
          style: getRegularStyle(
            fontSize: 12.sp,
            color: MosaedColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class UseCurrentLocationLink extends StatelessWidget {
  const UseCurrentLocationLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.my_location_rounded,
            size: 18.sp,
            color: MosaedColors.brand,
          ),
          SizedBox(width: 8.w),
          Text(
            'mosaedUseCurrentLocation'.tr(),
            style: getBoldStyle(fontSize: 13.sp, color: MosaedColors.brand),
          ),
        ],
      ),
    );
  }
}
