import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import '../constants/styles_manager.dart';

class MosaedDropdownItem<T> {
  const MosaedDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

class MosaedDropdown<T> extends StatefulWidget {
  const MosaedDropdown({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.selectedValue,
    this.trailing,
    this.isLoading = false,
  });

  final String title;
  final String hint;
  final IconData icon;
  final List<MosaedDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final Widget? trailing;
  final bool isLoading;

  @override
  State<MosaedDropdown<T>> createState() => _MosaedDropdownState<T>();
}

class _MosaedDropdownState<T> extends State<MosaedDropdown<T>> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String get _displayText {
    if (widget.selectedValue == null) return widget.hint;
    for (final item in widget.items) {
      if (item.value == widget.selectedValue) return item.label;
    }
    return widget.hint;
  }

  Future<void> _openMenu() async {
    if (widget.items.isEmpty || widget.isLoading) return;

    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    const menuMaxHeight = 220.0;
    final openBelow = spaceBelow >= menuMaxHeight;
    final menuTop = openBelow
        ? offset.dy + size.height + 2
        : offset.dy - menuMaxHeight - 2;

    final selected = await showMenu<T>(
      color: MosaedColors.surface,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: const BorderSide(color: MosaedColors.border),
      ),
      elevation: 4,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(offset.dx, menuTop, size.width, menuMaxHeight),
        screenSize,
      ),
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: menuMaxHeight,
      ),
      items: widget.items
          .map(
            (item) => PopupMenuItem<T>(
              value: item.value,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) widget.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(
            widget.title,
            style: getBoldStyle(
              fontSize: 16.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
        ],
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openMenu,
                borderRadius: BorderRadius.circular(10.r),
                child: Focus(
                  focusNode: _focusNode,
                  child: Container(
                    key: _fieldKey,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? MosaedColors.primary
                            : MosaedColors.border,
                      ),
                      color: MosaedColors.inputFill,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: 20.sp,
                          color: _focusNode.hasFocus
                              ? MosaedColors.primary
                              : MosaedColors.textSecondary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _displayText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: getRegularStyle(
                              fontSize: 14.sp,
                              color: hasSelection
                                  ? MosaedColors.textPrimary
                                  : MosaedColors.textHint,
                            ),
                          ),
                        ),
                        if (widget.isLoading)
                          SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 24.sp,
                            color: MosaedColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              SizedBox(width: 8.w),
              widget.trailing!,
            ],
          ],
        ),
      ],
    );
  }
}
