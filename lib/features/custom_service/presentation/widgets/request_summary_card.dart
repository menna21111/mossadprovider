import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../../core/widgets/mosaed_ribbon_card.dart';
import '../../../orders/data/provider_custom_request_model.dart';
import '../../../payments/presentation/widgets/payment_amount_text.dart';
import 'request_format_helpers.dart';

class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({
    super.key,
    required this.request,
    this.showOfferPrice = false,
  });

  final ProviderCustomRequest request;
  final bool showOfferPrice;

  @override
  Widget build(BuildContext context) {
    final specialization = request.specializationName?.trim() ?? '';
    final schedule = requestScheduleLabel(context, request.scheduledDate);
    final dayLabel = requestRelativeDayLabel(context, request.createdAt);
    final offer = request.myOffer;
    final price = offer?.displayPrice;

    return MosaedRibbonCard(
      statusLabel: 'mosaedCustomRequestBadge'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title.trim().isNotEmpty
                ? request.title.trim()
                : 'mosaedCustomServiceTitle'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: getBoldStyle(
              fontSize: 14.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                ImageAssets.time04,
                width: 14.w,
                height: 14.w,
                colorFilter: const ColorFilter.mode(
                  MosaedColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                dayLabel,
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (specialization.isNotEmpty)
                _MetaChip(
                  svgAsset: ImageAssets.orders,
                  label: specialization,
                ),
              _MetaChip(
                svgAsset: ImageAssets.time04,
                label: schedule,
                emphasized: true,
              ),
            ],
          ),
          if (showOfferPrice && price != null && price > 0) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Text(
                  '${'mosaedYourOfferAmount'.tr()} ',
                  style: getBoldStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.brand,
                  ),
                ),
                PaymentAmountText(
                  amount: price % 1 == 0
                      ? price.toStringAsFixed(0)
                      : price.toStringAsFixed(2),
                  color: MosaedColors.brand,
                  fontSize: 13,
                  iconSize: 12,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    this.icon,
    this.svgAsset,
    required this.label,
    this.emphasized = false,
  }) : assert(icon != null || svgAsset != null);

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fg = emphasized ? MosaedColors.brand : MosaedColors.textSecondary;
    final bg = emphasized ? MosaedColors.otpFill : const Color(0xFFF3F4F6);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null)
            SvgPicture.asset(
              svgAsset!,
              width: 13.w,
              height: 13.w,
              colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
            )
          else
            Icon(icon, size: 13.sp, color: fg),
          SizedBox(width: 5.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 120.w),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getMediumStyle(
                fontSize: 11.sp,
                color: emphasized ? MosaedColors.brand : MosaedColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
