import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/services/biometric_service.dart';

import '../data/auth_repository.dart';
import 'biometric_lock_screen.dart';
import 'cubit/auth_cubit.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/mosaed_logo.dart';

class LoginScrean extends StatefulWidget {
  const LoginScrean({super.key});

  @override
  State<LoginScrean> createState() => _LoginScreanState();
}

class _LoginScreanState extends State<LoginScrean> {
  final _formKey = GlobalKey<FormState>();
   final TextEditingController _phoneController = TextEditingController();

  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());


  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isFingerprintAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = available);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) {
    var phone = value.trim().replaceAll(' ', '');
    if (phone.startsWith('+966')) phone = phone.substring(4);
    if (phone.startsWith('966')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '0$phone';
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().sendOtp(_normalizePhone(_phoneController.text));
  }

  void _openBiometric() {
    final repo = context.read<AuthRepository>();
    if (!repo.canUseBiometricLogin) {
      AppFunctions.showsToast(
        repo.isBiometricEnabled && !repo.hasBiometricToken
            ? 'mosaedBiometricNeedLogin'.tr()
            : 'mosaedEnableBiometricFirst'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    AppFunctions.navigateToAndFinish(context, const BiometricLockScreen());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is OtpSent) {
          final otpCode = state.otpCode?.trim();
          if (otpCode != null && otpCode.isNotEmpty) {
            AppFunctions.showsToast(
              'mosaedOtpCodeToast'.tr(args: [otpCode]),
              MosaedColors.success,
              context,
            );
          }
          AppFunctions.navigateTo(
            context,
            OtpScreen(phoneNumber: state.phoneNumber),
            PageTransitionType.leftToRight,
          );
          context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: MosaedColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    const MosaedLogo(),
                    SizedBox(height: 28.h),
                    Text(
                      'mosaedWelcome'.tr(),
                      style: getBoldStyle(
                        fontSize: 24.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'mosaedLoginSubtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'mosaedPhoneLabel'.tr(),
                        style: getMediumStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    MosaedPhoneField(
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'mosaedPhoneRequired'.tr();
                        }
                        if (value.trim().length < 9) {
                          return 'mosaedPhoneInvalid'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),
                    MosaedPrimaryButton(
                      text: 'mosaedSendOtp'.tr(),
                      isLoading: isLoading,
                      icon: Icons.arrow_back_rounded,
                      onPressed: _sendOtp,
                    ),
                    SizedBox(height: 24.h),
                    if (_biometricAvailable) ...[
                      MosaedDividerText(text: 'mosaedOrLoginWith'.tr()),
                      SizedBox(height: 20.h),
                      Center(
                        child: InkWell(
                          onTap: _openBiometric,
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: MosaedColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: MosaedColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              color: MosaedColors.textPrimary,
                              size: 32.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 28.h),
                    GestureDetector(
                      onTap: () => AppFunctions.navigateTo(
                        context,
                        const RegisterScreen(),

PageTransitionType.leftToRight      ),
                      child: RichText(
                        text: TextSpan(
                          style: getRegularStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textSecondary,
                          ),
                          children: [
                            TextSpan(text: '${'mosaedNoAccount'.tr()} '),
                            TextSpan(
                              text: 'mosaedRegisterNow'.tr(),
                              style: getBoldStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'mosaedTerms'.tr(),
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
