import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mosaedprovider/features/auth/presentation/login_screen.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../app/theme_cubit.dart/theme_cubit.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/profile_shimmer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/models/customer_profile.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../notifications/presentation/cubit/notification_cubit.dart';
import '../../splash/presentation/splash_screen.dart';
import 'info_screen.dart';
import '../../services/presentation/addresses_list_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    context.read<AuthCubit>().fetchProfile();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<AuthRepository>();
    final fingerprintAvailable = await BiometricService.isFingerprintAvailable();
    if (mounted) {
      setState(() {
        _biometricAvailable = fingerprintAvailable;
        _biometricEnabled = repo.isBiometricEnabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final repo = context.read<AuthRepository>();

    if (value) {
      final result = await repo.setupBiometricLogin(
        promptMessage: 'mosaedBiometricReason'.tr(),
      );
      if (!result.success) {
        AppFunctions.showsToast(
          result.error ??
              (repo.hasBiometricToken
                  ? 'mosaedBiometricSetupFailed'.tr()
                  : 'mosaedBiometricNeedLogin'.tr()),
          MosaedColors.danger,
          context,
        );
        return;
      }
    } else {
      await repo.disableBiometric();
    }

    if (mounted) {
      setState(() => _biometricEnabled = value);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MosaedColors.surface,
        title: Text('logout'.tr()),
        content: Text('logoutConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => AppFunctions.navigateToAndFinish(context,  LoginScrean()),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(color: MosaedColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<AuthCubit>().logout();
  }

  void _openInfo(String titleKey, String bodyKey, {List<String> bullets = const []}) {
    AppFunctions.navigateTo(
      context,
      InfoScreen(titleKey: titleKey, bodyKey: bodyKey, bulletKeys: bullets),
      PageTransitionType.rightToLeft,
    );
  }

  Future<void> _editLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressesListScreen()),
    );
    if (mounted) context.read<AuthCubit>().fetchProfile();
  }

  CustomerProfile? _profileFromState(AuthState state) {
    if (state is ProfileLoaded) return state.profile;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthRepository>();

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          context.read<NotificationCubit>().stopRealtime();
          AppFunctions.navigateToAndFinish(context, const SplashScrean());
        } else if (state is AuthFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
        } else if (state is ProfileFailure) {
          AppFunctions.showsToast(state.message, MosaedColors.danger, context);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final profile = _profileFromState(state);
          final isLoading = state is ProfileLoading && profile == null;
          final name = profile?.name ?? repo.userName;
          final phone = profile?.phoneNumber ?? repo.storedPhone;
          final email = profile?.email;
          final defaultAddress = profile?.defaultAddress;
          final addressText = defaultAddress?.fullAddress ?? 'mosaedNoLocationYet'.tr();

          if (isLoading) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: const ProfileShimmer(),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MosaedColors.primary.withValues(alpha: 0.12),
                          MosaedColors.surface,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: MosaedColors.border),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36.r,
                          backgroundColor: MosaedColors.shieldBg,
                          child: Icon(
                            Icons.person_rounded,
                            color: MosaedColors.primary,
                            size: 36.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          name,
                          style: getBoldStyle(
                            fontSize: 20.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        if (phone != null && phone.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            phone,
                            style: getRegularStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                        ],
                        if (email != null && email.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            email,
                            style: getRegularStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                        ],
                        if (profile?.isPhoneVerified == true) ...[
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: MosaedColors.success,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'mosaedPhoneVerified'.tr(),
                                style: getMediumStyle(
                                  fontSize: 12.sp,
                                  color: MosaedColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'mosaedSavedLocation'.tr(),
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.location_on_rounded,
                          color: MosaedColors.primary,
                        ),
                        title: Text(
                          addressText,
                          style: getMediumStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        subtitle: Text('mosaedLocationProfileHint'.tr()),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _editLocation,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'mosaedSettings'.tr(),
                    children: [
                      BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, themeState) {
                          return SwitchListTile(
                            value: themeState.isDark,
                            activeThumbColor: MosaedColors.primary,
                            onChanged: (value) {
                              if (value) {
                                context.read<ThemeCubit>().setDarkTheme();
                              } else {
                                context.read<ThemeCubit>().setLightTheme();
                              }
                            },
                            title: Text('mosaedDarkMode'.tr()),
                            subtitle: Text('mosaedDarkModeSubtitle'.tr()),
                            secondary: Icon(
                              themeState.isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: MosaedColors.primary,
                            ),
                          );
                        },
                      ),
                      if (_biometricAvailable)
                        SwitchListTile(
                          value: _biometricEnabled,
                          activeThumbColor: MosaedColors.primary,
                          onChanged: _toggleBiometric,
                          title: Text('enableBiometric'.tr()),
                          subtitle: Text(
                            repo.hasBiometricToken
                                ? 'mosaedBiometricRealHint'.tr()
                                : 'mosaedBiometricNeedLogin'.tr(),
                          ),
                          secondary: Icon(
                            Icons.fingerprint_rounded,
                            color: MosaedColors.primary,
                          ),
                        ),
                      ListTile(
                        leading: Icon(
                          Icons.language_rounded,
                          color: MosaedColors.primary,
                        ),
                        title: Text('language'.tr()),
                        subtitle: Text(
                          context.locale.languageCode == 'ar'
                              ? 'arabic'.tr()
                              : 'english'.tr(),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          final locale = context.locale.languageCode == 'ar'
                              ? const Locale('en')
                              : const Locale('ar');
                          context.setLocale(locale);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'mosaedAppInfo'.tr(),
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: MosaedColors.primary,
                        ),
                        title: Text('mosaedAboutUs'.tr()),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openInfo('mosaedAboutUs', 'mosaedAboutUsBody'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.home_repair_service_outlined,
                          color: MosaedColors.primary,
                        ),
                        title: Text('mosaedOurServices'.tr()),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openInfo(
                          'mosaedOurServices',
                          'mosaedOurServicesBody',
                          bullets: const [
                            'mosaedPlumbing',
                            'mosaedInsulation',
                            'mosaedElectric',
                            'mosaedAc',
                            'mosaedCleaning',
                            'mosaedPainting',
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.support_agent_rounded,
                          color: MosaedColors.primary,
                        ),
                        title: Text('mosaedContactUs'.tr()),
                        subtitle: Text('support@mosaed.app'),
                        onTap: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'account'.tr(),
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.logout_rounded,
                          color: MosaedColors.danger,
                        ),
                        title: Text(
                          'logout'.tr(),
                          style: const TextStyle(color: MosaedColors.danger),
                        ),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
          child: Text(
            title,
            style: getBoldStyle(
              fontSize: 14.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: MosaedColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: MosaedColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
