import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

/// Terms & privacy agreement row with circular checkbox (design).
class TermsAgreeTile extends StatelessWidget {
  const TermsAgreeTile({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!agreed),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: MosaedColors.fieldBorder,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: agreed ? MosaedColors.brand : Colors.transparent,
                  border: Border.all(
                    color: agreed
                        ? MosaedColors.brand
                        : const Color(0xFFD0CBC9),
                    width: 1.5,
                  ),
                ),
                child: agreed
                    ? Icon(
                        Icons.check_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style: getSemiBoldStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(text: 'mosaedAgreePrefix'.tr()),
                      TextSpan(
                        text: 'mosaedTermsAndConditions'.tr(),
                        style: getSemiBoldStyle(
                      fontSize: 14.sp,
                          color: MosaedColors.brand,
                        ),
                      ),
                      TextSpan(text: 'mosaedAgreeAnd'.tr()),
                      TextSpan(
                        text: 'mosaedPrivacyPolicy'.tr(),
                        style:getSemiBoldStyle(
                      fontSize: 14.sp,
                          color: MosaedColors.brand,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
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
