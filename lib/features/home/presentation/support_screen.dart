import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import 'info_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _open(BuildContext context, String title, String body) {
    AppFunctions.navigateTo(
      context,
      InfoScreen(titleKey: title, bodyKey: body),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'mosaedSupport'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          _SupportTile(
            title: 'mosaedContactUs'.tr(),
            onTap: () => _open(
              context,
              'mosaedContactUs',
              'mosaedContactUsBody',
            ),
          ),
          SizedBox(height: 10.h),
          _SupportTile(
            title: 'mosaedSubmitComplaint'.tr(),
            onTap: () => _open(
              context,
              'mosaedSubmitComplaint',
              'mosaedSubmitComplaintBody',
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: getMediumStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: MosaedColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
