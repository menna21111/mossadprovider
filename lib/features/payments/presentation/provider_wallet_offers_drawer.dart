import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../home/presentation/offers_tab.dart';
import 'provider_dues_screen.dart';
import 'provider_wallet_screen.dart';
import 'cubit/provider_due_lock_cubit.dart';

class ProviderWalletOffersDrawer extends StatelessWidget {
  const ProviderWalletOffersDrawer({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    AppFunctions.navigateTo(context, screen, PageTransitionType.rightToLeft);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: BlocBuilder<ProviderDueLockCubit, ProviderDueLockState>(
          builder: (context, dueState) {
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_rounded, color: MosaedColors.primary, size: 24.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'mosaedProviderMenu'.tr(),
                        style: getBoldStyle(
                          fontSize: 18.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                if (dueState.isBlocked)
                  Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: MosaedColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: MosaedColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mosaedDuePaymentRequiredTitle'.tr(),
                          style: getMediumStyle(
                            fontSize: 13.sp,
                            color: MosaedColors.primary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'mosaedDueOutstandingAmount'.tr(
                            args: [dueState.outstandingAmount],
                          ),
                          style: getRegularStyle(
                            fontSize: 13.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                _MenuTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'mosaedWallet'.tr(),
                  subtitle: 'mosaedWalletSubtitle'.tr(),
                  onTap: () => _open(context, const ProviderWalletScreen()),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'mosaedDuePaymentRequiredTitle'.tr(),
                  subtitle: 'mosaedProviderDuesSubtitle'.tr(),
                  trailingText:
                      dueState.isBlocked ? dueState.outstandingAmount : null,
                  onTap: () => _open(context, const ProviderDuesScreen()),
                ),
                _MenuTile(
                  icon: Icons.local_offer_outlined,
                  title: 'mosaedMyOffers'.tr(),
                  subtitle: 'mosaedMyOffersSubtitle'.tr(),
                  onTap: () => _open(context, const _OffersShortcutScreen()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: MosaedColors.primary),
        title: Text(
          title,
          style: getMediumStyle(fontSize: 14.sp, color: MosaedColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: getRegularStyle(
            fontSize: 12.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        trailing: trailingText != null && trailingText!.trim().isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trailingText!,
                    style: getBoldStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: MosaedColors.textHint,
                    size: 18.sp,
                  ),
                ],
              )
            : Icon(
                Icons.chevron_left_rounded,
                color: MosaedColors.textHint,
                size: 20.sp,
              ),
      ),
    );
  }
}

class _OffersShortcutScreen extends StatelessWidget {
  const _OffersShortcutScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MosaedColors.background,
      body: SafeArea(child: OffersTab()),
    );
  }
}

