import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import 'home_relative_time.dart';

class MyWorksStatusBadge {
  const MyWorksStatusBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

/// Task card for «مهامي» — ribbon badge + title + time + description + chips.
class MyWorksJobCard extends StatelessWidget {
  const MyWorksJobCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.imageUrl,
    this.customerName,
    this.customerAvatar,
    this.createdAt,
    this.locationText,
    this.scheduledDate,
    this.distanceKm,
    this.photoCount,
    this.badgeLabel,
    this.badgeColor = MosaedColors.brand,
    this.badgeBackground = MosaedColors.otpFill,
    this.statusBadge,
    this.priceLabel,
    this.priceValue,
    this.showCustomer = false,
    this.showSideImage = false,
    this.height,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? customerName;
  final String? customerAvatar;
  final String? createdAt;
  final String? locationText;
  final String? scheduledDate;
  final double? distanceKm;
  final int? photoCount;
  final String? badgeLabel;
  final Color badgeColor;
  final Color badgeBackground;
  final MyWorksStatusBadge? statusBadge;
  final String? priceLabel;
  final double? priceValue;
  final bool showCustomer;
  final bool showSideImage;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final timeLabel = homeRelativeTime(createdAt);
    final name = (customerName ?? '').trim().isNotEmpty
        ? customerName!.trim()
        : 'mosaedClient'.tr();

    final chips = <(String, IconData, String?)>[
      if (distanceKm != null)
        (
          'mosaedDistanceKm'.tr(args: [distanceKm!.toStringAsFixed(1)]),
          Icons.location_on_outlined,
          ImageAssets.location,
        ),
      if ((locationText ?? '').trim().isNotEmpty)
        (
          locationText!,
          Icons.location_on_outlined,
          ImageAssets.location,
        ),
      if ((scheduledDate ?? '').trim().isNotEmpty)
        (
          scheduledDate!,
          Icons.calendar_today_outlined,
          ImageAssets.time04,
        ),
    ];

    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: MosaedColors.fieldBorder),
            color: MosaedColors.surfaceWhite,
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 34.h, 14.w, 14.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (statusBadge != null) ...[
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusBadge!.background,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            statusBadge!.label,
                            style: getMediumStyle(
                              fontSize: 10.sp,
                              color: statusBadge!.foreground,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: getBoldStyle(
                                  fontSize: 15.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                              if (showCustomer) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12.r,
                                      backgroundColor:
                                          MosaedColors.surfaceContainerLow,
                                      backgroundImage:
                                          (customerAvatar ?? '')
                                                  .trim()
                                                  .isNotEmpty
                                              ? NetworkImage(customerAvatar!)
                                              : null,
                                      child: (customerAvatar ?? '')
                                              .trim()
                                              .isEmpty
                                          ? Icon(
                                              Icons.person,
                                              size: 14.sp,
                                              color:
                                                  MosaedColors.textSecondary,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 6.w),
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: getBoldStyle(
                                          fontSize: 12.sp,
                                          color: MosaedColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (timeLabel.isNotEmpty) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14.sp,
                                      color: MosaedColors.textHint,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      timeLabel,
                                      style: getRegularStyle(
                                        fontSize: 12.sp,
                                        color: MosaedColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (description.trim().isNotEmpty) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: getRegularStyle(
                                    fontSize: 13.sp,
                                    color: MosaedColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (priceValue != null && priceValue! > 0) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Text(
                                      priceLabel ??
                                          'mosaedYourOfferAmount'.tr(),
                                      style: getBoldStyle(
                                        fontSize: 13.sp,
                                        color: MosaedColors.brand,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      priceValue!.toStringAsFixed(
                                        priceValue! % 1 == 0 ? 0 : 2,
                                      ),
                                      style: getBoldStyle(
                                        fontSize: 13.sp,
                                        color: MosaedColors.brand,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    SvgPicture.asset(
                                      ImageAssets.riyalIcon,
                                      width: 12.w,
                                      height: 12.w,
                                      colorFilter: const ColorFilter.mode(
                                        MosaedColors.brand,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showSideImage) ...[
                          SizedBox(width: 10.w),
                          _Thumb(
                            imageUrl: imageUrl,
                            photoCount: photoCount,
                          ),
                        ],
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          for (final chip in chips)
                            _MetaChip(
                              label: chip.$1,
                              fallbackIcon: chip.$2,
                              asset: chip.$3,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeLabel != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      badgeLabel!,
                      style: getMediumStyle(
                        fontSize: 11.sp,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl, this.photoCount});

  final String? imageUrl;
  final int? photoCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 78.w,
        height: 78.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((imageUrl ?? '').trim().isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            else
              _placeholder(),
            if ((photoCount ?? 0) > 0)
              Positioned(
                left: 6.w,
                bottom: 6.h,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        ImageAssets.cameraIcon,
                        width: 11.w,
                        height: 11.w,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        errorBuilder: (_, _, _) => Icon(
                          Icons.photo_camera_outlined,
                          size: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '$photoCount',
                        style: getBoldStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: MosaedColors.surfaceContainerLow,
      child: Icon(
        Icons.image_outlined,
        color: MosaedColors.textHint,
        size: 26.sp,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.fallbackIcon,
    this.asset,
  });

  final String label;
  final IconData fallbackIcon;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: MosaedColors.brandTransparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            SvgPicture.asset(
              asset!,
              width: 13.w,
              height: 13.w,
              colorFilter: const ColorFilter.mode(
                MosaedColors.brand,
                BlendMode.srcIn,
              ),
              errorBuilder: (_, _, _) => Icon(
                fallbackIcon,
                size: 13.sp,
                color: MosaedColors.brand,
              ),
            )
          else
            Icon(fallbackIcon, size: 13.sp, color: MosaedColors.brand),
          SizedBox(width: 4.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 160.w),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getMediumStyle(
                fontSize: 12.sp,
                color: MosaedColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
