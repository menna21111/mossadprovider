import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../orders/data/completion_form_model.dart';
import '../../../payments/presentation/widgets/payment_amount_text.dart';
import 'home_relative_time.dart';

/// Assigned job card for مهامي — booking completion-form fields.
class MyWorksAssignedCard extends StatelessWidget {
  const MyWorksAssignedCard({
    super.key,
    required this.form,
    required this.onTap,
    this.distanceKm,
  });

  final CompletionForm form;
  final VoidCallback onTap;
  final double? distanceKm;

  _AssignedStatusStyle get _status {
    if (form.isPaymentPending) {
      return _AssignedStatusStyle(
        label: form.paymentStatusLabelKey.tr(),
        foreground: const Color(0xFFB54708),
        background: const Color(0xFFFEF0C7),
      );
    }

    if (form.isFinished || form.paymentConfirmed) {
      return _AssignedStatusStyle(
        label: 'mosaedOfferCompletedBadge'.tr(),
        foreground: const Color(0xFF027A48),
        background: const Color(0xFFD1FADF),
      );
    }

    final s = (form.apiStatus ?? '').toLowerCase().trim();
    if (s == 'provider_arrived' || s.contains('arrived') || form.hasArrived) {
      return _AssignedStatusStyle(
        label: 'mosaedInProgress'.tr(),
        foreground: const Color(0xFF6941C6),
        background: const Color(0xFFEBE9FE),
      );
    }

    if (s == 'waiting' || s.contains('wait')) {
      return _AssignedStatusStyle(
        label: 'mosaedStatusWaiting'.tr(),
        foreground: MosaedColors.brand,
        background: MosaedColors.otpFill,
      );
    }

    return _AssignedStatusStyle(
      label: 'mosaedInProgress'.tr(),
      foreground: MosaedColors.brand,
      background: MosaedColors.otpFill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = form.displayTitle;
    final specialization = (form.specializationName ?? '').trim();
    final description = form.displayDescription.trim();
    final location = form.locationText.trim();
    final timeLabel = homeRelativeTime(
      form.isFinished ? (form.finishedAt ?? form.createdAt) : form.createdAt,
    );
    final status = _status;
    final price = form.finalPrice;
    final showDescription = description.isNotEmpty &&
        description != specialization &&
        description != title;

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
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: form.isCustomRequest
                          ? const Color(0xFFDEFFEB)
                          : MosaedColors.otpFill,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      form.isCustomRequest
                          ? 'mosaedCustomRequestBadge'.tr()
                          : 'mosaedBookingTaskBadge'.tr(),
                      style: getMediumStyle(
                        fontSize: 10.sp,
                        color: form.isCustomRequest
                            ? const Color(0xFF1B7A4A)
                            : MosaedColors.brand,
                      ),
                    ),
                  ),
                  const Spacer(),
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
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AssignedThumb(imageUrl: form.cardImage),
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
                        if (specialization.isNotEmpty &&
                            specialization != title) ...[
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
                ],
              ),
              if (showDescription) ...[
                SizedBox(height: 10.h),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (location.isNotEmpty || distanceKm != null) ...[
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
                        [
                          if (distanceKm != null)
                            'mosaedDistanceAway'
                                .tr(args: [distanceKm!.toStringAsFixed(1)]),
                          if (location.isNotEmpty) location,
                        ].join(' · '),
                        maxLines: 2,
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
                    child: price != null && price > 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'mosaedFinalPrice'.tr(),
                                style: getRegularStyle(
                                  fontSize: 11.sp,
                                  color: MosaedColors.textHint,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              PaymentAmountText(
                                amount: price.toStringAsFixed(
                                  price == price.roundToDouble() ? 0 : 2,
                                ),
                                color: MosaedColors.brand,
                                fontSize: 15,
                                iconSize: 13,
                              ),
                            ],
                          )
                        : Text(
                            form.isFinished
                                ? 'mosaedOfferCompletedBadge'.tr()
                                : 'mosaedInProgress'.tr(),
                            style: getRegularStyle(
                              fontSize: 12.sp,
                              color: MosaedColors.textSecondary,
                            ),
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

class _AssignedThumb extends StatelessWidget {
  const _AssignedThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 56.w,
        height: 56.w,
        child: url.isEmpty
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder();
                },
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: MosaedColors.otpFill,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        ImageAssets.activeWorksIcon,
        width: 22.w,
        height: 22.w,
        colorFilter: const ColorFilter.mode(
          MosaedColors.brand,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _AssignedStatusStyle {
  const _AssignedStatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
