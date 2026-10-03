import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class PaymentAmountText extends StatelessWidget {
  const PaymentAmountText({
    super.key,
    required this.amount,
    this.color,
    this.fontSize,
    this.iconSize,
    this.prefix,
  });

  final String amount;
  final Color? color;
  final double? fontSize;
  final double? iconSize;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final c = color ?? MosaedColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null) ...[
          Text(
            prefix!,
            style: getBoldStyle(fontSize: (fontSize ?? 14).sp, color: c),
          ),
          SizedBox(width: 2.w),
        ],
        Text(
          amount,
          style: getBoldStyle(fontSize: (fontSize ?? 14).sp, color: c),
        ),
        SizedBox(width: 4.w),
        SvgPicture.asset(
          ImageAssets.riyalIcon,
          width: (iconSize ?? 12).w,
          height: (iconSize ?? 12).w,
          colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
        ),
      ],
    );
  }
}

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    super.key,
    required this.mainLabel,
    required this.mainAmount,
    required this.leftLabel,
    required this.leftAmount,
    required this.rightLabel,
    required this.rightAmount,
  });

  final String mainLabel;
  final String mainAmount;
  final String leftLabel;
  final String leftAmount;
  final String rightLabel;
  final String rightAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: MosaedColors.brand,
            size: 28.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            mainLabel,
            style: getRegularStyle(
              fontSize: 13.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          PaymentAmountText(
            amount: mainAmount,
            color: MosaedColors.brand,
            fontSize: 28,
            iconSize: 18,
          ),
          SizedBox(height: 16.h),
          const Divider(height: 1, color: MosaedColors.fieldBorder),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: rightLabel,
                  amount: rightAmount,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: MosaedColors.fieldBorder,
              ),
              Expanded(
                child: _Stat(
                  label: leftLabel,
                  amount: leftAmount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: getRegularStyle(
            fontSize: 12.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        PaymentAmountText(
          amount: amount,
          color: MosaedColors.textPrimary,
          fontSize: 15,
          iconSize: 12,
        ),
      ],
    );
  }
}
