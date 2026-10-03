import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import '../constants/styles_manager.dart';

/// Pill tab bar matching mossad task/service details:
/// white stadium container, soft orange fill when selected.
class MosaedPillTabs extends StatelessWidget {
  const MosaedPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height,
    this.fontSize,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double? height;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (height ?? 46).h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _PillTab(
                label: labels[i],
                selected: selectedIndex == i,
                fontSize: fontSize ?? 13,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fontSize,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? MosaedColors.brandTransparent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (selected ? getBoldStyle : getMediumStyle)(
              fontSize: fontSize.sp,
              color: selected ? MosaedColors.brand : MosaedColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
