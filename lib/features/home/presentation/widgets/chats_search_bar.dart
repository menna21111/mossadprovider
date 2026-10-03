import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class ChatsSearchBar extends StatelessWidget {
  const ChatsSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    final side = const BorderSide(color: MosaedColors.fieldBorder);
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: getRegularStyle(
          fontSize: 14.sp,
          color: MosaedColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: MosaedColors.surfaceWhite,
          hintText: 'mosaedSearchChatsHint'.tr(),
          hintStyle: getRegularStyle(
            fontSize: 14.sp,
            color: MosaedColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22.sp,
            color: MosaedColors.textHint,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20.sp,
                    color: MosaedColors.textHint,
                  ),
                )
              : null,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          border: OutlineInputBorder(borderRadius: radius, borderSide: side),
          enabledBorder:
              OutlineInputBorder(borderRadius: radius, borderSide: side),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: MosaedColors.brand, width: 1.4),
          ),
        ),
      ),
    );
  }
}
