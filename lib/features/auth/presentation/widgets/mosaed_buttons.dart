import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class MosaedPrimaryButton extends StatelessWidget {
  const MosaedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled,
    this.isLoading = false,
    this.showLoadingIndicator = true,
    this.icon,
    this.fontSize,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool? enabled;
  final bool isLoading;
  final bool showLoadingIndicator;
  final IconData? icon;
  final double? fontSize;

  bool get _isActive => enabled ?? (onPressed != null);

  Color get _backgroundColor => _isActive
      ? MosaedColors.brand
      : MosaedColors.brand.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    final canTap = _isActive && !isLoading && onPressed != null;

    return GestureDetector(
      onTap: canTap ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: radius,
        ),
        child: isLoading && showLoadingIndicator
            ? Center(
                child: SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null && !isLoading) ...[
                    Icon(
                      icon,
                      color: Colors.white.withValues(
                        alpha: _isActive ? 1 : 0.85,
                      ),
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: getBoldStyle(
                      fontSize: (fontSize ?? 16).sp,
                      color: Colors.white.withValues(
                        alpha: _isActive ? 1 : 0.85,
                      ),
                    ),
                  ),
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
    this.color,
    this.foregroundColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? MosaedColors.brand;
    final foreground = foregroundColor ?? color;
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          backgroundColor: MosaedColors.surfaceWhite,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 18.sp),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: getBoldStyle(
                  fontSize: 15.sp,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Converts Eastern Arabic / Persian digits to ASCII, leaving other chars.
String mosaedToAsciiDigits(String value) {
  final buffer = StringBuffer();
  for (final unit in value.codeUnits) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.write(unit - 0x0660);
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.write(unit - 0x06F0);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

int mosaedPhoneDigitCount(String value) =>
    mosaedToAsciiDigits(value).replaceAll(RegExp(r'\D'), '').length;

class MosaedPhoneField extends StatelessWidget {
  const MosaedPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.left,
        validator: validator,
        onChanged: onChanged,
        style: getRegularStyle(
          fontSize: 15.sp,
          color: MosaedColors.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsetsDirectional.only(start: 12.w, end: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: SvgPicture.asset(
                    ImageAssets.saudiFlag,
                    width: 24.w,
                    height: 16.h,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: MosaedColors.textSecondary,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  '+966',
                  style: getRegularStyle(
                    fontSize: 15.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 110.w, minHeight: 0),
          hintText: '5X XXX XXXX',
          hintStyle: getRegularStyle(
            fontSize: 15.sp,
            color: MosaedColors.textHint,
          ),
          filled: true,
          fillColor: MosaedColors.surfaceWhite,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 14.h,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(
              color: MosaedColors.fieldBorder,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: MosaedColors.brand, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: MosaedColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: MosaedColors.danger, width: 1),
          ),
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
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: getMediumStyle(
              fontSize: 16.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          validator: validator,
          textAlign: TextAlign.start,
          style: getRegularStyle(
            fontSize: 15.sp,
            color: MosaedColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: getRegularStyle(
              fontSize: 15.sp,
              color: MosaedColors.textHint,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: MosaedColors.brand, size: 20.sp)
                : null,
            filled: true,
            fillColor: MosaedColors.surfaceWhite,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: MosaedColors.fieldBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide:
                  const BorderSide(color: MosaedColors.brand, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: MosaedColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: MosaedColors.danger,
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
        Expanded(
          child: Divider(color: MosaedColors.brand.withValues(alpha: 0.35)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            text,
            style: getSemiBoldStyle(
                      fontSize: 14.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: MosaedColors.brand.withValues(alpha: 0.35)),
        ),
      ],
    );
  }
}
