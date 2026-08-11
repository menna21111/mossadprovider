import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/auth_navigation.dart';
import '../../../app/functions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/caching/cach_helper.dart';
import '../../../core/services/biometric_service.dart';

import '../data/auth_repository.dart';
import 'biometric_success_screen.dart';
import 'cubit/auth_cubit.dart';
import 'login_screen.dart';
import 'widgets/mosaed_buttons.dart';

enum _BiometricLockState { ready, needsSetup, notLoggedIn, deviceUnavailable }

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _verified = false;
  bool _isLoading = false;
  bool _isSettingUp = false;
  _BiometricLockState _state = _BiometricLockState.ready;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkBiometricAvailability(),
    );
  }

  Future<void> _checkBiometricAvailability() async {
    final fingerprintAvailable =
        await BiometricService.isFingerprintAvailable();
    final token = CacheHelper().getDataString(
      key: AppConstants.biometricTokenKey,
    );
    final isLoggedIn = context.read<AuthRepository>().isLoggedIn;

    if (!fingerprintAvailable) {
      if (mounted) {
        setState(() {
          _state = _BiometricLockState.deviceUnavailable;
          _statusMessage = 'mosaedBiometricDeviceUnavailable'.tr();
        });
      }
      return;
    }

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _state = isLoggedIn
              ? _BiometricLockState.needsSetup
              : _BiometricLockState.notLoggedIn;
          _statusMessage = isLoggedIn
              ? 'mosaedBiometricNeedsSetup'.tr()
              : 'mosaedBiometricNotLoggedIn'.tr();
        });
      }
      return;
    }

    if (mounted) setState(() => _state = _BiometricLockState.ready);
    Future.delayed(const Duration(milliseconds: 600), _authenticate);
  }

  Future<void> _setupBiometric() async {
    if (_isSettingUp) return;
    setState(() => _isSettingUp = true);

    final result = await context.read<AuthRepository>().setupBiometricLogin(
      promptMessage: 'mosaedBiometricReason'.tr(),
    );

    if (!mounted) return;
    setState(() => _isSettingUp = false);

    if (result.success) {
      AppFunctions.navigateToAndFinish(context, const BiometricSuccessScreen());
      return;
    }

    AppFunctions.showsToast(
      result.error ?? 'mosaedBiometricSetupFailed'.tr(),
      MosaedColors.danger,
      context,
    );
  }

  Future<void> _authenticate() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _verified = false;
    });

    context.read<AuthCubit>().loginWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthVerified) {
          setState(() {
            _verified = true;
            _isLoading = false;
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              AuthNavigation.goAfterBiometricUnlock(context);
            }
          });
          context.read<AuthCubit>().reset();
        } else if (state is AuthFailure) {
          setState(() => _isLoading = false);
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
          context.read<AuthCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoggedIn = context.read<AuthRepository>().isLoggedIn;
        final showStatusPanel = _state != _BiometricLockState.ready;

        return Scaffold(
          backgroundColor: MosaedColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showStatusPanel) ...[
                    SizedBox(height: 60.h),
                    _StatusCard(state: _state, message: _statusMessage!),
                    SizedBox(height: 40.h),
                    if (_state == _BiometricLockState.needsSetup)
                      MosaedPrimaryButton(
                        text: 'mosaedBiometricActivateNow'.tr(),
                        icon: Icons.fingerprint_rounded,
                        isLoading: _isSettingUp,
                        onPressed: _setupBiometric,
                      )
                    else if (_state == _BiometricLockState.deviceUnavailable &&
                        isLoggedIn)
                      MosaedPrimaryButton(
                        text: 'mosaedContinue'.tr(),
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () =>
                            AuthNavigation.goAfterBiometricUnlock(context),
                      )
                    else
                      MosaedPrimaryButton(
                        text: 'mosaedBiometricUseOtpInstead'.tr(),
                        icon: Icons.dialpad_rounded,
                        onPressed: () {
                          AppFunctions.navigateToAndFinish(
                            context,
                            const LoginScrean(),
                          );
                        },
                      ),
                    if (_state == _BiometricLockState.deviceUnavailable) ...[
                      SizedBox(height: 16.h),
                      MosaedOutlineButton(
                        text: 'mosaedBiometricOpenSettings'.tr(),
                        icon: Icons.settings,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('mosaedBiometricSettingsTitle'.tr()),
                              content: Text('mosaedBiometricSettingsBody'.tr()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('mosaedBiometricUnderstood'.tr()),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ] else ...[
                    SizedBox(height: 32.h),
                    FadeIn(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 32.h,
                        ),
                        decoration: BoxDecoration(
                          color: MosaedColors.surface,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                color: MosaedColors.successBg,
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: MosaedColors.success.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 64.sp,
                                    color: MosaedColors.primary,
                                  ),
                                  if (_isLoading)
                                    SizedBox(
                                      width: 100.w,
                                      child: LinearProgressIndicator(
                                        color: MosaedColors.primary,
                                        backgroundColor: MosaedColors.border,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'mosaedWelcomeBack'.tr(),
                              style: getBoldStyle(
                                fontSize: 22.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'mosaedBiometricInstruction'.tr(),
                              textAlign: TextAlign.center,
                              style: getRegularStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textSecondary,
                              ),
                            ),
                            if (!_isLoading) ...[
                              SizedBox(height: 24.h),
                              MosaedPrimaryButton(
                                text: 'mosaedBiometricLoginButton'.tr(),
                                icon: Icons.fingerprint_rounded,
                                onPressed: _authenticate,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  if (_verified)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: MosaedColors.success,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'mosaedVerifiedSuccess'.tr(),
                          style: getMediumStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.success,
                          ),
                        ),
                      ],
                    ),
                  MosaedOutlineButton(
                    text: 'mosaedUseOtpInstead'.tr(),
                    icon: Icons.dialpad_rounded,
                    onPressed: () {
                      AppFunctions.navigateToAndFinish(
                        context,
                        const LoginScrean(),
                      );
                    },
                  ),
                  // SizedBox(height: 20.h),
                  // Text(
                  //   'Mosaed v${AppConstants.appVersion} • ${'mosaedHighSecurity'.tr()}',
                  //   style: getRegularStyle(
                  //     fontSize: 11.sp,
                  //     color: MosaedColors.textHint,
                  //   ),
                  // ),
                  // SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.message});

  final _BiometricLockState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isSetup = state == _BiometricLockState.needsSetup;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isSetup
            ? MosaedColors.primary.withValues(alpha: 0.08)
            : MosaedColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSetup
              ? MosaedColors.primary.withValues(alpha: 0.3)
              : MosaedColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSetup ? Icons.fingerprint_rounded : Icons.warning_rounded,
            size: 48.sp,
            color: isSetup ? MosaedColors.primary : MosaedColors.danger,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: getMediumStyle(
              fontSize: 14.sp,
              color: isSetup ? MosaedColors.textPrimary : MosaedColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
