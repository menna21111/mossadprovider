import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../app/theme_cubit.dart/theme_cubit.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/services/biometric_service.dart';
import '../../auth/data/auth_repository.dart';
import 'notification_settings_screen.dart';
import 'widgets/language_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<AuthRepository>();
    if (mounted) {
      setState(() => _biometricEnabled = repo.isBiometricEnabled);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final repo = context.read<AuthRepository>();
    final available = await BiometricService.isFingerprintAvailable();
    if (!available) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedBiometricDeviceUnavailable'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (value) {
      final result = await repo.setupBiometricLogin(
        promptMessage: 'mosaedBiometricReason'.tr(),
      );
      if (!result.success) {
        if (!mounted) return;
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
    if (mounted) setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          'mosaedSettings'.tr(),
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
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return _SettingsSwitchTile(
                title: 'mosaedDarkMode'.tr(),
                value: themeState.isDark,
                onChanged: (value) {
                  if (value) {
                    context.read<ThemeCubit>().setDarkTheme();
                  } else {
                    context.read<ThemeCubit>().setLightTheme();
                  }
                },
              );
            },
          ),
          SizedBox(height: 10.h),
          _SettingsSwitchTile(
            title: 'mosaedBiometricFaceTitle'.tr(),
            subtitle: 'mosaedBiometricFaceSubtitle'.tr(),
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
          ),
          SizedBox(height: 10.h),
          _SettingsNavTile(
            title: 'language'.tr(),
            onTap: () => LanguageSheet.show(context),
          ),
          SizedBox(height: 10.h),
          _SettingsNavTile(
            title: 'mosaedNotifications'.tr(),
            onTap: () {
              AppFunctions.navigateTo(
                context,
                const NotificationSettingsScreen(),
                PageTransitionType.rightToLeft,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getMediumStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle!,
                    style: getRegularStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: MosaedColors.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({required this.title, required this.onTap});

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
                Icons.chevron_left_rounded,
                size: 22.sp,
                color: MosaedColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
