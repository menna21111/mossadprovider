import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/auth_navigation.dart';
import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/mosaed_logo.dart';


class BiometricSuccessScreen extends StatefulWidget {
  const BiometricSuccessScreen({super.key});

  @override
  State<BiometricSuccessScreen> createState() => _BiometricSuccessScreenState();
}

class _BiometricSuccessScreenState extends State<BiometricSuccessScreen> {
  int _seconds = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        _goHome();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _goHome() {
    if (!mounted) return;
    AuthNavigation.goAfterLogin(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              const MosaedLogo(width: 180, showTagline: true),
              SizedBox(height: 36.h),
              FadeInDown(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: MosaedColors.surface,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 64.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: const BoxDecoration(
                        color: MosaedColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'mosaedBiometricActivated'.tr(),
                style: getBoldStyle(
                  fontSize: 22.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'mosaedBiometricActivatedDesc'.tr(),
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: MosaedColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: MosaedColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: MosaedColors.shieldBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: MosaedColors.primaryDark,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'mosaedAuthStatus'.tr(),
                            style: getRegularStyle(
                              fontSize: 12.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                          Text(
                            'mosaedAccountLinked'.tr(),
                            style: getBoldStyle(
                              fontSize: 14.sp,
                              color: MosaedColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              MosaedPrimaryButton(
                text: 'mosaedGoHome'.tr(),
                icon: Icons.arrow_back_rounded,
                onPressed: _goHome,
              ),
              SizedBox(height: 12.h),
              Text(
                'mosaedAutoRedirect'.tr(args: ['$_seconds']),
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
