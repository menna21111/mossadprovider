import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class MosaedPrimaryButton extends StatelessWidget {
  const MosaedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MosaedColors.primaryContainer,
          disabledBackgroundColor:
              MosaedColors.primaryContainer.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: getBoldStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: 8.w),
                    Icon(icon, color: Colors.white, size: 18.sp),
                  ],
                ],
              ),
      ),
    );
  }
}

class MosaedOutlineButton extends StatelessWidget {
  const MosaedOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: MosaedColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          backgroundColor: MosaedColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: MosaedColors.textSecondary, size: 18.sp),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: getMediumStyle(
                  fontSize: 10.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MosaedPhoneField extends StatelessWidget {
  const MosaedPhoneField({super.key, required this.controller, this.validator});

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      validator: validator,
      style: getRegularStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
      decoration: InputDecoration(
        hintText: '5XXXXXXXX',
        hintStyle: getRegularStyle(
          fontSize: 15.sp,
          color: MosaedColors.textHint,
        ),
        prefixIcon: Icon(
          Icons.smartphone_outlined,
          color: MosaedColors.textSecondary,
          size: 20.sp,
        ),
        suffixIcon: Container(
          width: 90.w,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+966',
                style: getMediumStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: MosaedColors.textSecondary,
                size: 20.sp,
              ),
              Container(
                width: 1,
                height: 24.h,
                margin: EdgeInsets.only(left: 8.w),
                color: MosaedColors.border,
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: MosaedColors.inputFill,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: MosaedColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: MosaedColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: MosaedColors.danger),
        ),
      ),
    );
  }
}

class MosaedInputField extends StatelessWidget {
  const MosaedInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          validator: validator,
          style: getRegularStyle(
            fontSize: 15.sp,
            color: MosaedColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: getRegularStyle(
              fontSize: 14.sp,
              color: MosaedColors.textHint,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: MosaedColors.textSecondary, size: 20.sp)
                : null,
            filled: true,
            fillColor: MosaedColors.inputFill,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: MosaedColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(
                color: MosaedColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MosaedDividerText extends StatelessWidget {
  const MosaedDividerText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: MosaedColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            text,
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: MosaedColors.border)),
      ],
    );
  }
}
