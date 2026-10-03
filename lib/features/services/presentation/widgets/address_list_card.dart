import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../data/models/address_models.dart';
import 'address_place_type.dart';

class AddressListCard extends StatelessWidget {
  const AddressListCard({
    super.key,
    required this.address,
    required this.onEdit,
    this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isPrimary = address.isDefault;
    final type = addressPlaceTypeFromLabel(address.label);
    final title = address.label != null &&
            address.label!.trim().isNotEmpty &&
            type == AddressPlaceType.other &&
            !_isKnownLabel(address.label!)
        ? address.label!.trim()
        : type.label;
    final subtitle =
        address.shortAddress.isNotEmpty ? address.shortAddress : address.fullAddress;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: isPrimary ? MosaedColors.otpFill : MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPrimary ? MosaedColors.cardBorder : MosaedColors.fieldBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPrimary
                      ? MosaedColors.brand
                      : MosaedColors.surfaceContainerLow,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  ImageAssets.locationProfile,
                  width: 20.w,
                  height: 20.w,
                  colorFilter: ColorFilter.mode(
                    isPrimary ? Colors.white : MosaedColors.brand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: getBoldStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: getRegularStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPrimary)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: MosaedColors.brand,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'mosaedPrimaryBadge'.tr(),
                    style: getBoldStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _PillButton(
                text: 'mosaedEdit'.tr(),
                icon: Icons.edit_outlined,
                foreground: MosaedColors.brand,
                background: MosaedColors.surfaceWhite,
                border: MosaedColors.brand,
                onTap: onEdit,
              ),
              if (onDelete != null) ...[
                SizedBox(width: 8.w),
                _PillButton(
                  text: 'mosaedDelete'.tr(),
                  icon: Icons.delete_outline_rounded,
                  foreground: MosaedColors.danger,
                  background: const Color(0xFFFEECEC),
                  border: const Color(0xFFF5C2C2),
                  onTap: onDelete!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _isKnownLabel(String label) {
    final v = label.trim().toLowerCase();
    const known = [
      'home',
      'work',
      'other',
      'المنزل',
      'العمل',
      'أخرى',
      'اخرى',
    ];
    return known.contains(v);
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: foreground),
              SizedBox(width: 6.w),
              Text(
                text,
                style: getBoldStyle(fontSize: 12.sp, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
