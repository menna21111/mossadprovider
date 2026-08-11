import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import 'cubit/provider_due_lock_cubit.dart';


class ProviderDueLockDialog extends StatelessWidget {
  const ProviderDueLockDialog({
    super.key,
    required this.state,
  });

  final ProviderDueLockState state;

  Future<void> _openPaymentLink() async {
    final link = state.currentPaymentLink.trim();
    if (link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'mosaedCurrency'.tr();
    final amount = state.outstandingAmount.trim();

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: MosaedColors.surfaceWhite,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: MosaedColors.danger,
                      size: 28.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'mosaedDuePaymentRequiredTitle'.tr(),
                        style: getBoldStyle(
                          fontSize: 18.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: MosaedColors.primaryContainer
                              .withValues(alpha: 0.12),
                          border: Border.all(
                            color: MosaedColors.primaryContainer
                                .withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'mosaedDueOutstandingAmount'.tr(
                                args: [amount],
                              ),
                              style: getRegularStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              '$amount $currency',
                              style: getBoldStyle(
                                fontSize: 22.sp,
                                color: MosaedColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'mosaedDueLockHint'.tr(),
                        textAlign: TextAlign.center,
                        style: getRegularStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 26.h),
                      MosaedPrimaryButton(
                        text: 'mosaedPayNow'.tr(),
                        onPressed: _openPaymentLink,
                        icon: Icons.payment_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

