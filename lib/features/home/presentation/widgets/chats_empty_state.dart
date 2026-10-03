import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class ChatsEmptyState extends StatelessWidget {
  const ChatsEmptyState({
    super.key,
    required this.onRefresh,
    required this.image,
    required this.titleKey,
    required this.bodyKey,
  });

  final Future<void> Function() onRefresh;
  final String image;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: MosaedColors.brand,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: _ChatsEmptyIllustration(
                  image: image,
                  titleKey: titleKey,
                  bodyKey: bodyKey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatsEmptyIllustration extends StatelessWidget {
  const _ChatsEmptyIllustration({
    required this.image,
    required this.titleKey,
    required this.bodyKey,
  });

  final String image;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              image,
              width: 220.w,
              height: 200.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              titleKey.tr(),
              textAlign: TextAlign.center,
              style: getBoldStyle(
                fontSize: 17.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              bodyKey.tr(),
              textAlign: TextAlign.center,
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
