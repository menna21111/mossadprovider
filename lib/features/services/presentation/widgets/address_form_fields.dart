import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

InputDecoration addressFieldDecoration({
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final radius = BorderRadius.circular(12.r);
  return InputDecoration(
    hintText: hint,
    hintStyle: getRegularStyle(
      fontSize: 13.sp,
      color: MosaedColors.textHint,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: MosaedColors.surfaceWhite,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: MosaedColors.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: MosaedColors.brand, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: MosaedColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: MosaedColors.danger, width: 1.5),
    ),
  );
}

class AddressFieldLabel extends StatelessWidget {
  const AddressFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: getMediumStyle(
          fontSize: 12.sp,
          color: MosaedColors.textPrimary,
        ),
      ),
    );
  }
}

Widget addressAssetIcon(String asset) {
  return Padding(
    padding: EdgeInsetsDirectional.only(start: 12.w, end: 8.w),
    child: SvgPicture.asset(
      asset,
      width: 20.w,
      height: 20.w,
    ),
  );
}

class AddressTextField extends StatelessWidget {
  const AddressTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.iconAsset,
    this.validator,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String iconAsset;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressFieldLabel(label),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: getRegularStyle(
            fontSize: 13.sp,
            color: MosaedColors.textPrimary,
          ),
          decoration: addressFieldDecoration(
            hint: hint,
            prefixIcon: addressAssetIcon(iconAsset),
          ),
        ),
      ],
    );
  }
}

class AddressDropdownField<T> extends StatelessWidget {
  const AddressDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.iconAsset,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String iconAsset;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressFieldLabel(label),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          // ignore: deprecated_member_use — controlled dropdown needs value
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: MosaedColors.textSecondary,
            size: 22.sp,
          ),
          style: getRegularStyle(
            fontSize: 13.sp,
            color: MosaedColors.textPrimary,
          ),
          decoration: addressFieldDecoration(
            hint: hint,
            prefixIcon: addressAssetIcon(iconAsset),
          ),
          hint: Text(
            hint,
            style: getRegularStyle(
              fontSize: 13.sp,
              color: MosaedColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
