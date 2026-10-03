import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

Future<void> showFingerprintSuccessSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => FingerprintSuccessSheet(
      title: title ?? 'mosaedFingerprintRegistered'.tr(),
      subtitle: subtitle ?? 'mosaedFingerprintRegisteredHint'.tr(),
    ),
  );
}

class FingerprintSuccessSheet extends StatefulWidget {
  const FingerprintSuccessSheet({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  State<FingerprintSuccessSheet> createState() =>
      _FingerprintSuccessSheetState();
}

class _FingerprintSuccessSheetState extends State<FingerprintSuccessSheet> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = (widget.subtitle ?? '').trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(32.w, 12.h, 32.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MosaedColors.fieldBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 28.h),
              Image.asset(
                ImageAssets.fingerprintSuccess,
                width: 140.w,
                height: 140.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.h),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: getBoldStyle(
                  fontSize: 16.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: getRegularStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
