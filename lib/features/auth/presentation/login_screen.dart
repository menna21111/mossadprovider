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
import 'otp_bottom_sheet.dart';
import 'register_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_rich_link.dart';
import 'widgets/mosaed_buttons.dart';
import 'widgets/terms_agree_tile.dart';

class LoginScrean extends StatefulWidget {
  const LoginScrean({super.key});

  @override
  State<LoginScrean> createState() => _LoginScreanState();
}

class _LoginScreanState extends State<LoginScrean> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  bool _biometricAvailable = false;
  bool _otpSheetOpen = false;

  bool get _canSubmit =>
      _agreedToTerms && mosaedPhoneDigitCount(_phoneController.text) >= 9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isFingerprintAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) {
    var phone = mosaedToAsciiDigits(value).trim().replaceAll(' ', '');
    if (phone.startsWith('+966')) phone = phone.substring(4);
    if (phone.startsWith('966')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '0$phone';
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      AppFunctions.showsToast(
        'mosaedAcceptTermsRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
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
          if (!_otpSheetOpen) {
            _otpSheetOpen = true;
            OtpBottomSheet.show(
              context,
              phoneNumber: state.phoneNumber,
            ).whenComplete(() {
              if (mounted) _otpSheetOpen = false;
            });
          }
          context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: MosaedColors.surfaceWhite,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20.h),
                          AuthHeader(
                            title: 'mosaedWelcome'.tr(),
                            subtitle: 'mosaedLoginSubtitle'.tr(),
                            logoWidth: 142,
                            logoHeight: 195,
                          ),
                          SizedBox(height: 28.h),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'mosaedPhoneLabel'.tr(),
                              style: getMediumStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          MosaedPhoneField(
                            controller: _phoneController,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'mosaedPhoneRequired'.tr();
                              }
                              if (mosaedPhoneDigitCount(value) < 9) {
                                return 'mosaedPhoneInvalid'.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          TermsAgreeTile(
                            agreed: _agreedToTerms,
                            onChanged: (value) =>
                                setState(() => _agreedToTerms = value),
                          ),
                          SizedBox(height: 20.h),
                          AuthRichLink(
                            prefix: 'mosaedNoAccount'.tr(),
                            action: 'mosaedRegisterNow'.tr(),
                            onTap: () => AppFunctions.navigateTo(
                              context,
                              const RegisterScreen(),
                              PageTransitionType.leftToRight,
                            ),
                          ),
                          if (_biometricAvailable) ...[
                            SizedBox(height: 28.h),
                            MosaedDividerText(text: 'mosaedOrLoginWith'.tr()),
                            SizedBox(height: 16.h),
                            _BiometricButton(onTap: _openBiometric),
                          ],
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: MosaedColors.surfaceWhite,
                      border: Border(
                        top: BorderSide(
                          color: MosaedColors.fieldBorder,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 24.w, 16.h),
                    child: MosaedPrimaryButton(
                      text: 'mosaedLogin'.tr(),
                      isLoading: isLoading,
                      enabled: _canSubmit,
                      fontSize: 15,
                      onPressed: _canSubmit ? _sendOtp : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: MosaedColors.primaryContainer,
              width: 1.4,
            ),
          ),
          child: Icon(
            Icons.fingerprint_rounded,
            color: MosaedColors.primaryContainer,
            size: 28.sp,
          ),
        ),
      ),
    );
  }
}
