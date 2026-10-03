import 'dart:async';
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

/// OTP verification as a bottom sheet (mossad design).
class OtpBottomSheet extends StatefulWidget {
  const OtpBottomSheet({super.key, required this.phoneNumber});

  final String phoneNumber;

  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
  }) {
    final cubit = context.read<AuthCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: OtpBottomSheet(phoneNumber: phoneNumber),
      ),
    );
  }

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  static const _resendSeconds = 60;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    if (_hasError) {
      setState(() => _hasError = false);
    } else {
      setState(() {});
    }
  }

  bool get _isOtpComplete => _otpController.text.length == 6;

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _displayPhone {
    var phone = widget.phoneNumber.trim();
    if (phone.startsWith('0') && phone.length >= 10) {
      phone = '+966 ${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+966 $phone';
    }
    return phone;
  }

  void _verify() {
    if (!_isOtpComplete) return;
    setState(() => _hasError = false);
    context.read<AuthCubit>().verifyOtp(
          phoneNumber: widget.phoneNumber,
          otpCode: _otpController.text,
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    context.read<AuthCubit>().sendOtp(widget.phoneNumber);
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final defaultPinTheme = PinTheme(
      width: 55.w,
      height: 55.w,
      textStyle: getBoldStyle(
        fontSize: 18.sp,
        color: MosaedColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MosaedColors.fieldBorder, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      textStyle: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
      decoration: defaultPinTheme.decoration?.copyWith(
        color: MosaedColors.otpFill,
        border: Border.all(color: MosaedColors.brand, width: 1.4),
      ),
    );

    final filledPinTheme = defaultPinTheme.copyWith(
      textStyle: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
      decoration: defaultPinTheme.decoration?.copyWith(
        color: MosaedColors.otpFill,
        border: Border.all(color: MosaedColors.fieldBorder, width: 1),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      textStyle: getBoldStyle(fontSize: 18.sp, color: MosaedColors.danger),
      decoration: defaultPinTheme.decoration?.copyWith(
        color: MosaedColors.surfaceWhite,
        border: Border.all(color: MosaedColors.danger, width: 1.4),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: MosaedColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: SafeArea(
          top: false,
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state is AuthVerified) {
                await _handleVerified();
                if (context.mounted) context.read<AuthCubit>().reset();
              } else if (state is OtpSent) {
                final otpCode = state.otpCode?.trim();
                if (otpCode != null && otpCode.isNotEmpty) {
                  AppFunctions.showsToast(
                    'mosaedOtpCodeToast'.tr(args: [otpCode]),
                    MosaedColors.success,
                    context,
                  );
                }
                _startTimer();
                setState(() => _hasError = false);
                context.read<AuthCubit>().reset();
              } else if (state is AuthFailure) {
                setState(() => _hasError = true);
                AppFunctions.showsToast(
                  state.message,
                  MosaedColors.danger,
                  context,
                );
                context.read<AuthCubit>().reset();
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final canResend = _secondsLeft == 0 && !isLoading;
              final canVerify = _isOtpComplete && !isLoading;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: MosaedColors.fieldBorder,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'mosaedVerifyPhoneTitle'.tr(),
                      textAlign: TextAlign.center,
                      style: getBoldStyle(
                        fontSize: 18.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'mosaedVerifyPhoneSubtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: getMediumStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _displayPhone,
                      textAlign: TextAlign.center,
                      textDirection: ui.TextDirection.ltr,
                      style: getMediumStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Pinput(
                        length: 6,
                        controller: _otpController,
                        focusNode: _focusNode,
                        enabled: !isLoading,
                        forceErrorState: _hasError,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: filledPinTheme,
                        followingPinTheme: defaultPinTheme,
                        errorPinTheme: errorPinTheme,
                        onChanged: (_) {},
                      ),
                    ),
                    SizedBox(height: 20.h),
                    if (_secondsLeft > 0)
                      Text(
                        'mosaedResendIn'.tr(args: [_timerLabel]),
                        textAlign: TextAlign.center,
                        style: getMediumStyle(
                          fontSize: 14.sp,
                          color: MosaedColors.brand,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'mosaedChangePhone'.tr(),
                        textAlign: TextAlign.center,
                        style: getBoldStyle(
                          fontSize: 14.sp,
                          color: MosaedColors.brand,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    MosaedPrimaryButton(
                      text: isLoading
                          ? 'mosaedVerifying'.tr()
                          : 'mosaedVerify'.tr(),
                      isLoading: isLoading,
                      showLoadingIndicator: false,
                      fontSize: 15,
                      onPressed: canVerify ? _verify : null,
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: canResend ? _resend : null,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: getRegularStyle(
                            fontSize: 13.sp,
                            color: MosaedColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: '${'mosaedDidntReceiveCode'.tr()} ',
                            ),
                            TextSpan(
                              text: 'mosaedResend'.tr(),
                              style: getBoldStyle(
                                fontSize: 13.sp,
                                color: canResend
                                    ? MosaedColors.brand
                                    : MosaedColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
