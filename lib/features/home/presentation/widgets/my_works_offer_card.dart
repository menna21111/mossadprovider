import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../orders/data/provider_offer_model.dart';
import '../../../payments/presentation/widgets/payment_amount_text.dart';
import 'home_relative_time.dart';

class MyWorksOfferCard extends StatelessWidget {
  const MyWorksOfferCard({
    super.key,
    required this.offer,
    required this.onTap,
  });

  final ProviderOffer offer;
  final VoidCallback onTap;

  _OfferStatusStyle get _status {
    final request = (offer.requestStatus ?? '').toLowerCase();
    final status = (offer.status ?? '').toLowerCase();

    if (offer.isRejected ||
        status.contains('reject') ||
        status.contains('decline')) {
      return _OfferStatusStyle(
        label: 'mosaedOfferRejectedBadge'.tr(),
        foreground: const Color(0xFFB42318),
        background: const Color(0xFFFEE4E2),
      );
    }

    if (request.contains('complete') ||
        request.contains('done') ||
        request.contains('finish')) {
      return _OfferStatusStyle(
        label: 'mosaedOfferCompletedBadge'.tr(),
        foreground: const Color(0xFF027A48),
        background: const Color(0xFFD1FADF),
      );
    }

    if (request.contains('progress') ||
        request.contains('active') ||
        request.contains('working') ||
        request.contains('in_progress')) {
      return _OfferStatusStyle(
        label: 'mosaedInProgress'.tr(),
        foreground: const Color(0xFF6941C6),
        background: const Color(0xFFEBE9FE),
      );
    }

    if (offer.isPending) {
      return _OfferStatusStyle(
        label: 'mosaedOfferStatusPending'.tr(),
        foreground: MosaedColors.brand,
        background: MosaedColors.brandTransparent,
      );
    }

    if (offer.isAccepted) {
      return _OfferStatusStyle(
        label: 'mosaedOfferAcceptedBadge'.tr(),
        foreground: const Color(0xFF027A48),
        background: const Color(0xFFD1FADF),
      );
    }

    return _OfferStatusStyle(
      label: 'mosaedOfferStatusPending'.tr(),
      foreground: MosaedColors.textSecondary,
      background: MosaedColors.surfaceContainerLow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (offer.customRequestTitle ?? '').trim().isNotEmpty
        ? offer.customRequestTitle!.trim()
        : 'mosaedCustomRequest'.tr();
    final specialization = (offer.specializationName ?? '').trim();
    final note = (offer.note ?? '').trim();
    final location = offer.locationText.trim();
    final timeLabel = homeRelativeTime(offer.createdAt);
    final status = _status;
    final providerPrice = offer.providerPrice;
    final finalPrice = offer.finalPrice;

    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: MosaedColors.otpFill,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: MosaedColors.brand,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: getBoldStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textPrimary,
                          ),
                        ),
                        if (specialization.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            specialization,
                            style: getRegularStyle(
                              fontSize: 12.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: status.background,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      status.label,
                      style: getMediumStyle(
                        fontSize: 11.sp,
                        color: status.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (location.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SvgPicture.asset(
                      ImageAssets.location,
                      width: 14.w,
                      height: 14.w,
                      colorFilter: const ColorFilter.mode(
                        MosaedColors.textHint,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getRegularStyle(
                          fontSize: 12.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12.h),
              const Divider(height: 1, color: MosaedColors.fieldBorder),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mosaedYourOfferAmount'.tr(),
                          style: getRegularStyle(
                            fontSize: 11.sp,
                            color: MosaedColors.textHint,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        PaymentAmountText(
                          amount: providerPrice > 0
                              ? providerPrice.toStringAsFixed(
                                  providerPrice == providerPrice.roundToDouble()
                                      ? 0
                                      : 2,
                                )
                              : '0',
                          color: MosaedColors.brand,
                          fontSize: 15,
                          iconSize: 13,
                        ),
                        if (finalPrice != null &&
                            finalPrice > 0 &&
                            finalPrice != providerPrice) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                '${'mosaedFinalPrice'.tr()}: ',
                                style: getRegularStyle(
                                  fontSize: 11.sp,
                                  color: MosaedColors.textHint,
                                ),
                              ),
                              PaymentAmountText(
                                amount: finalPrice.toStringAsFixed(
                                  finalPrice == finalPrice.roundToDouble()
                                      ? 0
                                      : 2,
                                ),
                                color: MosaedColors.textSecondary,
                                fontSize: 11,
                                iconSize: 10,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (timeLabel.isNotEmpty)
                    Text(
                      timeLabel,
                      style: getRegularStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.textHint,
                      ),
                    ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 20.sp,
                    color: MosaedColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferStatusStyle {
  const _OfferStatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
