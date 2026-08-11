import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/mosaed_colors.dart';
import '../../features/services/data/models/existed_service.dart';

class ServiceThumbnail extends StatelessWidget {
  const ServiceThumbnail({
    super.key,
    required this.service,
    this.size,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final ExistedService service;
  final double? size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 44.w;
    final radius = borderRadius ?? BorderRadius.circular(12.r);

    if (service.hasImage) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          service.image!,
          width: dimension,
          height: dimension,
          fit: fit,
          errorBuilder: (_, __, ___) => _iconBox(dimension, radius),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _loadingBox(dimension, radius);
          },
        ),
      );
    }

    return _iconBox(dimension, radius);
  }

  Widget _iconBox(double dimension, BorderRadius radius) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: service.accentColor.withValues(alpha: 0.12),
        borderRadius: radius,
      ),
      child: Icon(
        service.icon,
        color: service.accentColor,
        size: dimension * 0.55,
      ),
    );
  }

  Widget _loadingBox(double dimension, BorderRadius radius) {
    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MosaedColors.inputFill,
        borderRadius: radius,
      ),
      child: SizedBox(
        width: dimension * 0.35,
        height: dimension * 0.35,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
