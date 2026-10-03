import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

enum AddressPlaceType { home, work, other }

AddressPlaceType addressPlaceTypeFromLabel(String? label) {
  final v = (label ?? '').trim().toLowerCase();
  if (v.isEmpty) return AddressPlaceType.home;
  const workKeys = ['work', 'العمل', 'عمل'];
  const homeKeys = ['home', 'المنزل', 'منزل'];
  const otherKeys = ['other', 'أخرى', 'اخرى'];
  if (workKeys.any(v.contains)) return AddressPlaceType.work;
  if (homeKeys.any(v.contains)) return AddressPlaceType.home;
  if (otherKeys.any(v.contains)) return AddressPlaceType.other;
  return AddressPlaceType.other;
}

extension AddressPlaceTypeX on AddressPlaceType {
  String get label => switch (this) {
        AddressPlaceType.home => 'mosaedLabelHome'.tr(),
        AddressPlaceType.work => 'mosaedLabelWork'.tr(),
        AddressPlaceType.other => 'mosaedLabelOther'.tr(),
      };

  String? get iconAsset => switch (this) {
        AddressPlaceType.home => ImageAssets.houseIcon,
        AddressPlaceType.work => ImageAssets.buildingOffice,
        AddressPlaceType.other => null,
      };

  IconData get icon => switch (this) {
        AddressPlaceType.home => Icons.home_rounded,
        AddressPlaceType.work => Icons.apartment_rounded,
        AddressPlaceType.other => Icons.more_horiz_rounded,
      };
}

class AddressTypeTiles extends StatelessWidget {
  const AddressTypeTiles({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AddressPlaceType value;
  final ValueChanged<AddressPlaceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in AddressPlaceType.values) ...[
          if (type != AddressPlaceType.values.first) SizedBox(width: 10.w),
          Expanded(
            child: _TypeTile(
              type: type,
              selected: value == type,
              onTap: () => onChanged(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AddressPlaceType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MosaedColors.brand : MosaedColors.textSecondary;
    final asset = type.iconAsset;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? MosaedColors.brand : MosaedColors.fieldBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              if (asset != null)
                SvgPicture.asset(
                  asset,
                  width: 26.w,
                  height: 26.w,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else
                Icon(type.icon, color: color, size: 26.sp),
              SizedBox(height: 8.h),
              Text(
                type.label,
                style: getMediumStyle(fontSize: 12.sp, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
