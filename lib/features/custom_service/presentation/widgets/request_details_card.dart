import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../../core/widgets/mosaed_horizontal_photos.dart';
import '../../../../core/widgets/mosaed_labeled_row.dart';
import '../../../orders/data/provider_custom_request_model.dart';
import 'request_format_helpers.dart';

class RequestDetailsCard extends StatelessWidget {
  const RequestDetailsCard({super.key, required this.request});

  final ProviderCustomRequest request;

  @override
  Widget build(BuildContext context) {
    final photos = request.images;
    final orderNo = requestOrderNumber(request.id);
    final schedule = requestScheduleLabel(context, request.scheduledDate);
    final missing = 'mosaedNotAvailableYet'.tr();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 10.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.fieldBorder),
        boxShadow: MosaedColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'mosaedDetailsSection'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.brand),
          ),
          SizedBox(height: 16.h),
          MosaedLabeledRow(
            svgAsset: ImageAssets.note01,
            label: 'mosaedProblemLabel'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              request.title.trim().isNotEmpty
                  ? request.title.trim()
                  : 'mosaedCustomServiceTitle'.tr(),
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.message02,
            label: 'mosaedProblemDescription'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              request.description.trim().isNotEmpty
                  ? request.description.trim()
                  : '—',
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.orders,
            label: 'mosaedServiceType'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              request.specializationName?.trim().isNotEmpty == true
                  ? request.specializationName!
                  : missing,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.image02,
            label: 'mosaedProblemPhotos'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: photos.isEmpty
                ? Text(
                    '—',
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  )
                : MosaedHorizontalPhotos(urls: photos),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.chooseCity,
            label: 'mosaedServiceLocationShort'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              request.locationText.trim().isNotEmpty
                  ? request.locationText
                  : missing,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.time04,
            label: 'mosaedAppointment'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              schedule,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.orderHash,
            label: 'mosaedOrderNumber'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              orderNo,
              style: getBoldStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }
}
