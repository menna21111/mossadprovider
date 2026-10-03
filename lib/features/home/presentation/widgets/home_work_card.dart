import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

class HomeWorkCard extends StatelessWidget {
  const HomeWorkCard({
    super.key,
    required this.badge,
    required this.title,
    required this.personName,
    required this.timeLabel,
    required this.description,
    required this.onTap,
    this.imageUrl,
    this.personAvatar,
    this.photoCount,
    this.distanceKm,
    this.locationText,
    this.scheduledDate,
    this.statusLabel,
    this.badgeColor = const Color(0xFF1B7A4A),
    this.badgeBackground = const Color(0xFFDEFFEB),
    this.width,
    this.height,
  });

  final String badge;
  final String? imageUrl;
  final String title;
  final String personName;
  final String? personAvatar;
  final String timeLabel;
  final String description;
  final int? photoCount;
  final double? distanceKm;
  final String? locationText;
  final String? scheduledDate;
  final String? statusLabel;
  final Color badgeColor;
  final Color badgeBackground;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, IconData, String?)>[
      if ((scheduledDate ?? '').trim().isNotEmpty)
        (
          scheduledDate!,
          Icons.calendar_today_outlined,
          ImageAssets.calendar03,
        ),
      if ((locationText ?? '').trim().isNotEmpty)
        (
          locationText!,
          Icons.location_on_outlined,
          ImageAssets.location,
        ),
      if (distanceKm != null)
        (
          'mosaedDistanceKm'.tr(args: [distanceKm!.toStringAsFixed(1)]),
          Icons.location_on_outlined,
          ImageAssets.location,
        ),
      if ((statusLabel ?? '').trim().isNotEmpty)
        (
          statusLabel!,
          Icons.work_outline_rounded,
          null,
        ),
    ];

    return SizedBox(
      width: width ?? 300.w,
      height: height,
      child: Material(
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
                  padding: EdgeInsets.fromLTRB(12.w, 30.h, 12.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [ Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: getBoldStyle(
                                      fontSize: 18.sp,
                                      color: MosaedColors.textPrimary,
                                    ),
                                  ), SizedBox(height: 8.h),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                           
                                 
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24.r,
                                        backgroundColor:
                                            MosaedColors.surfaceContainerLow,
                                        backgroundImage: (personAvatar ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? NetworkImage(personAvatar!)
                                            : null,
                                        child: (personAvatar ?? '')
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            personName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: getMediumStyle(
                                              fontSize: 16.sp,
                                              color: MosaedColors.textPrimary,
                                            ),
                                          ),  if (timeLabel.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12.sp,
                                          color: MosaedColors.textHint,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          timeLabel,
                                          style: getRegularStyle(
                                            fontSize: 14.sp,
                                            color: MosaedColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                          
                                        ],
                                      ),
                                    ],
                                  ),
                                
                                  if (description.trim().isNotEmpty) ...[
                                    SizedBox(height: 6.h),
                                    Expanded(
                                      child: Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: getRegularStyle(
                                          fontSize: 14.sp,
                                          color: MosaedColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            _Thumb(
                              imageUrl: imageUrl,
                              photoCount: photoCount,
                            ),
                          ],
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < chips.length; i++) ...[
                                if (i > 0) SizedBox(width: 6.w),
                                _MetaChip(
                                  label: chips[i].$1,
                                  fallbackIcon: chips[i].$2,
                                  asset: chips[i].$3,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
                      badge,
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
        width: 116.w,
        height: 102.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.trim().isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            else
              _placeholder(),
            if (photoCount != null && photoCount! > 0)
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
                          fontSize: 12.sp,
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
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: MosaedColors.textHint,
          size: 26.sp,
        ),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
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
              width: 12.w,
              height: 12.w,
              colorFilter: const ColorFilter.mode(
                MosaedColors.brand,
                BlendMode.srcIn,
              ),
              errorBuilder: (_, _, _) => Icon(
                fallbackIcon,
                size: 12.sp,
                color: MosaedColors.brand,
              ),
            )
          else
            Icon(fallbackIcon, size: 12.sp, color: MosaedColors.brand),
          SizedBox(width: 4.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 110.w),
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
