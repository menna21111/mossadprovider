import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_empty_strip.dart';

class HomeWorkList extends StatelessWidget {
  const HomeWorkList({
    super.key,
    required this.isEmpty,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    this.emptyImage,
    this.height,
    this.emptyHeight,
  });

  final bool isEmpty;
  final String emptyMessage;
  final String? emptyImage;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final double? height;
  final double? emptyHeight;

  @override
  Widget build(BuildContext context) {
    final listHeight = isEmpty && emptyImage != null
        ? (emptyHeight ?? 210.h)
        : (height ?? 140.h);

    return SizedBox(
      height: listHeight,
      child: isEmpty
          ? HomeEmptyStrip(message: emptyMessage, image: emptyImage)
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: itemBuilder,
            ),
    );
  }
}
