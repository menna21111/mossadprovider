import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../services/presentation/address_onboarding_screen.dart';
import '../data/auth_repository.dart';
import 'cubit/auth_cubit.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/mosaed_logo.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    if (_otpController.text.length != 6) {
      AppFunctions.showsToast(
        'mosaedOtpIncomplete'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    context.read<AuthCubit>().verifyOtp(
          phoneNumber: widget.phoneNumber,
          otpCode: _otpController.text,
        );
  }

  Future<void> _handleVerified() async {
    context.read<AuthRepository>().registerBiometricInBackground();
    if (!mounted) return;
    AppFunctions.navigateToAndFinish(
      context,
      const AddressOnboardingScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 52.h,
      textStyle: getBoldStyle(
        fontSize: 20.sp,
        color: MosaedColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: MosaedColors.inputFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MosaedColors.border),
      ),
    );

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthVerified) {
          await _handleVerified();
          if (context.mounted) context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: MosaedColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: MosaedColors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const MosaedLogo(width: 180, showTagline: false),
                  SizedBox(height: 24.h),
                  Text(
                    'mosaedOtpTitle'.tr(),
                    style: getBoldStyle(
                      fontSize: 22.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'mosaedOtpSubtitle'.tr(args: [widget.phoneNumber]),
                    textAlign: TextAlign.center,
                    style: getRegularStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration?.copyWith(
                          border: Border.all(
                            color: MosaedColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  MosaedPrimaryButton(
                    text: 'confirm'.tr(),
                    isLoading: isLoading,
                    onPressed: _verify,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<AuthCubit>()
                            .sendOtp(widget.phoneNumber),
                    child: Text(
                      'resendCode'.tr(),
                      style: getMediumStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
