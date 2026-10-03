import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/widgets/mosaed_confirm_dialog.dart';
import '../../../core/widgets/profile_shimmer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/models/customer_profile.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../payments/presentation/bank_accounts_screen.dart';
import '../../payments/presentation/provider_dues_screen.dart';
import '../../payments/presentation/provider_wallet_screen.dart';
import '../../services/presentation/addresses_list_screen.dart';
import '../../splash/presentation/splash_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'widgets/language_sheet.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().fetchProfile();
  }

  Future<void> _logout() async {
    final confirmed = await showMosaedConfirmDialog(
      context,
      title: 'logout'.tr(),
      message: 'mosaedLogoutQuestion'.tr(),
      confirmText: 'logout'.tr(),
    );
    if (!confirmed || !mounted) return;
    context.read<AuthCubit>().logout();
  }

  Future<void> _openEdit(CustomerProfile? profile) async {
    final fallback = CustomerProfile(
      id: '',
      name: context.read<AuthRepository>().userName,
      phoneNumber: context.read<AuthRepository>().storedPhone ?? '',
      addresses: const [],
      isPhoneVerified: false,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile ?? fallback),
      ),
    );
    if (mounted) context.read<AuthCubit>().fetchProfile();
  }

  Future<void> _openAddresses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressesListScreen()),
    );
    if (!mounted) return;
    context.read<AuthCubit>().fetchProfile();
  }

  CustomerProfile? _profileFromState(AuthState state) {
    if (state is ProfileLoaded) return state.profile;
    return null;
  }

  String _languageLabel(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'en':
        return 'english'.tr();
      default:
        return 'arabic'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthRepository>();

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
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
          final name = profile?.name.isNotEmpty == true
              ? profile!.name
              : repo.userName;

          return Scaffold(
            backgroundColor: MosaedColors.surfaceWhite,
            appBar: AppBar(
              backgroundColor: MosaedColors.surfaceWhite,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Text(
                'mosaedMore'.tr(),
                style: getBoldStyle(
                  fontSize: 16.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.h),
                child: const Divider(
                  height: 1,
                  color: MosaedColors.fieldBorder,
                ),
              ),
            ),
            body: isLoading
                ? Padding(
                    padding: EdgeInsets.all(20.w),
                    child: const ProfileShimmer(),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    children: [
                      _ProfileHeader(
                        name: name,
                        avatarUrl: profile?.avatar,
                        onEdit: () => _openEdit(profile),
                      ),
                      SizedBox(height: 22.h),
                      _MenuSection(
                        title: 'account'.tr(),
                        children: [
                          _MenuTile(
                            asset: ImageAssets.userIconProfile,
                            label: 'mosaedMyAccount'.tr(),
                            onTap: () => _openEdit(profile),
                          ),
                          _MenuTile(
                            asset: ImageAssets.locationProfile,
                            label: 'mosaedMyAddresses'.tr(),
                            showDivider: false,
                            onTap: _openAddresses,
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      _MenuSection(
                        title: 'mosaedFinances'.tr(),
                        children: [
                          _MenuTile(
                            asset: ImageAssets.profits,
                            label: 'mosaedMyProfits'.tr(),
                            onTap: () {
                              AppFunctions.navigateTo(
                                context,
                                const ProviderWalletScreen(),
                                PageTransitionType.rightToLeft,
                              );
                            },
                          ),
                          _MenuTile(
                            asset: ImageAssets.bankAccount,
                            label: 'mosaedBankAccount'.tr(),
                            onTap: () {
                              AppFunctions.navigateTo(
                                context,
                                const BankAccountsScreen(),
                                PageTransitionType.rightToLeft,
                              );
                            },
                          ),
                          _MenuTile(
                            asset: ImageAssets.profitsOfMansa,
                            label: 'mosaedPlatformDues'.tr(),
                            showDivider: false,
                            onTap: () {
                              AppFunctions.navigateTo(
                                context,
                                const ProviderDuesScreen(),
                                PageTransitionType.rightToLeft,
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      _MenuSection(
                        title: 'mosaedHelpAndSettings'.tr(),
                        children: [
                          _MenuTile(
                            asset: ImageAssets.settings01,
                            label: 'mosaedSettings'.tr(),
                            onTap: () {
                              AppFunctions.navigateTo(
                                context,
                                const SettingsScreen(),
                                PageTransitionType.rightToLeft,
                              );
                            },
                          ),
                          _MenuTile(
                            asset: ImageAssets.languageIcon,
                            label: _languageLabel(context),
                            showDivider: false,
                            onTap: () => LanguageSheet.show(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      _MenuSection(
                        title: 'mosaedHelpAndAbout'.tr(),
                        children: [
                          _MenuTile(
                            asset: ImageAssets.mail01,
                            label: 'mosaedSupport'.tr(),
                            showDivider: false,
                            onTap: () {
                              AppFunctions.navigateTo(
                                context,
                                const SupportScreen(),
                                PageTransitionType.rightToLeft,
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      MosaedOutlineButton(
                        text: 'logout'.tr(),
                        icon: Icons.logout_rounded,
                        color: MosaedColors.danger,
                        onPressed: _logout,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.onEdit,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: MosaedColors.otpFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: MosaedColors.fieldBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.person_rounded,
                          color: MosaedColors.brand,
                          size: 24.sp,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: MosaedColors.brand,
                        size: 24.sp,
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: getBoldStyle(
                        fontSize: 15.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'mosaedEditProfile'.tr(),
                      style: getRegularStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
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

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h, right: 4.w, left: 4.w),
          child: Text(
            title,
            style: getBoldStyle(
              fontSize: 13.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.asset,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: MosaedColors.brandTransparent,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: SvgPicture.asset(
              asset,
              width: 18.w,
              height: 18.w,
            ),
          ),
          title: Text(
            label,
            style: getMediumStyle(
              fontSize: 14.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 20.sp,
            color: MosaedColors.textHint,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: MosaedColors.fieldBorder,
          ),
      ],
    );
  }
}
