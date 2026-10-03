import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import 'mosaed_status_ribbon.dart';

class MosaedRibbonCard extends StatelessWidget {
  const MosaedRibbonCard({
    super.key,
    required this.statusLabel,
    required this.child,
    this.onTap,
    this.padding,
  });

  final String statusLabel;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    final body = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: MosaedColors.softShadow,
      ),
      child: Material(
        color: MosaedColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: MosaedColors.fieldBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: padding ?? EdgeInsets.fromLTRB(14.w, 32.h, 14.w, 14.h),
              child: child,
            ),
            MosaedStatusRibbon(label: statusLabel),
          ],
        ),
      ),
    );

    if (onTap == null) return body;

    return InkWell(onTap: onTap, borderRadius: radius, child: body);
  }
}
