import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';

class MosaedHorizontalPhotos extends StatelessWidget {
  const MosaedHorizontalPhotos({
    super.key,
    required this.urls,
    this.size = 64,
  });

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dim = size.w;

    return SizedBox(
      height: dim,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.network(
            urls[i],
            width: dim,
            height: dim,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: MosaedColors.surfaceContainerLow,
              child: SizedBox(
                width: dim,
                height: dim,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: MosaedColors.textHint,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
