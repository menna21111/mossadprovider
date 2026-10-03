import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/functions.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key, required this.hostContext});

  final BuildContext hostContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => LanguageSheet(hostContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
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
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'language'.tr(),
                      style: getBoldStyle(
                        fontSize: 16.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: MosaedColors.textSecondary,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _LanguageTile(
                title: 'العربية',
                subtitle: 'Arabic',
                selected: current == 'ar',
                onTap: () => _select(context, const Locale('ar')),
              ),
              SizedBox(height: 10.h),
              _LanguageTile(
                title: 'English',
                subtitle: 'الإنجليزية',
                selected: current == 'en',
                onTap: () => _select(context, const Locale('en')),
              ),
              SizedBox(height: 10.h),
              _LanguageTile(
                title: 'اردو',
                subtitle: 'Urdu',
                selected: current == 'ur',
                onTap: () {
                  Navigator.pop(context);
                  AppFunctions.showsToast(
                    'mosaedLanguageComingSoon'.tr(),
                    MosaedColors.brand,
                    hostContext,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, Locale locale) async {
    if (context.locale == locale) {
      Navigator.pop(context);
      return;
    }
    await context.setLocale(locale);
    if (context.mounted) Navigator.pop(context);
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? MosaedColors.brand.withValues(alpha: 0.08)
          : MosaedColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? MosaedColors.brand : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: getBoldStyle(
                        fontSize: 14.sp,
                        color: selected
                            ? MosaedColors.brand
                            : MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: getRegularStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    color: MosaedColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
