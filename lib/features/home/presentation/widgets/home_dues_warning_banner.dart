import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/functions.dart';
import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../../payments/presentation/cubit/provider_due_lock_cubit.dart';
import '../../../payments/presentation/provider_dues_screen.dart';
import '../../../payments/presentation/widgets/payment_amount_text.dart';

class HomeDuesWarningBanner extends StatelessWidget {
  const HomeDuesWarningBanner({super.key});

  Future<void> _pay(BuildContext context, ProviderDueLockState state) async {
    final link = state.currentPaymentLink.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    AppFunctions.navigateTo(
      context,
      const ProviderDuesScreen(),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderDueLockCubit, ProviderDueLockState>(
      builder: (context, state) {
        if (state.isBlocked || !state.hasOutstanding) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF5D0B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                   
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'mosaedLastWarningBeforeRestriction'.tr(),
                            style: getBoldStyle(
                              fontSize: 15.sp,
                              color: MosaedColors.danger,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'mosaedOutstandingDuesPrefix'.tr(),
                                style: getRegularStyle(
                                  fontSize: 15.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              PaymentAmountText(
                                amount: state.outstandingAmount,
                                color: MosaedColors.brand,
                                fontSize: 16,
                                iconSize: 12,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'mosaedPayWithin3Days'.tr(),
                            style: getRegularStyle(
                              fontSize: 14.sp,
                              color: MosaedColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ), SizedBox(width: 12.w), Image.asset(
                      ImageAssets.holdAccount,
                      width: 56.w,
                      height: 56.w,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                MosaedPrimaryButton(
                  text: 'mosaedPayDues'.tr(),
                  fontSize: 18,
                  onPressed: () => _pay(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
