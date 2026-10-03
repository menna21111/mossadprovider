import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/functions.dart';
import '../../../app/navigator_key.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../home/presentation/support_screen.dart';
import 'cubit/provider_due_lock_cubit.dart';
import 'provider_dues_screen.dart';
import 'widgets/payment_amount_text.dart';

class ProviderDueLockDialog extends StatelessWidget {
  const ProviderDueLockDialog({
    super.key,
    required this.state,
  });

  final ProviderDueLockState state;

  Future<void> _openPayment(BuildContext context) async {
    final link = state.currentPaymentLink.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final nav = navigatorKey.currentContext;
    if (nav == null) return;
    AppFunctions.navigateTo(
      nav,
      const ProviderDuesScreen(),
      PageTransitionType.rightToLeft,
    );
  }

  void _openSupport(BuildContext context) {
    final nav = navigatorKey.currentContext;
    if (nav == null) return;
    AppFunctions.navigateTo(
      nav,
      const SupportScreen(),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = state.outstandingAmount.trim().isEmpty
        ? '0'
        : state.outstandingAmount.trim();

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: MosaedColors.fieldBorder,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: MosaedColors.danger,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          ImageAssets.holdIcon,
                          width: 14.w,
                          height: 14.w,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'mosaedAccountRestrictedBadge'.tr(),
                          style: getBoldStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'mosaedAccountRestrictedTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: getBoldStyle(
                      fontSize: 20.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'mosaedAccountRestrictedBody'.tr(),
                    textAlign: TextAlign.center,
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: MosaedColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: MosaedColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          ImageAssets.profits,
                          width: 22.w,
                          height: 22.w,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${'mosaedTotalDuesLabel'.tr()}: ',
                                style: getBoldStyle(
                                  fontSize: 14.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                              PaymentAmountText(
                                amount: amount,
                                color: MosaedColors.textPrimary,
                                fontSize: 14,
                                iconSize: 13,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MosaedPrimaryButton(
                    text: 'mosaedPayDues'.tr(),
                    onPressed: () => _openPayment(context),
                  ),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () => _openSupport(context),
                    child: Text(
                      'mosaedContactSupport'.tr(),
                      style: getBoldStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
