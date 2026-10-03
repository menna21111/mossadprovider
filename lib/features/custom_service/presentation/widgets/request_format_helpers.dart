import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String requestScheduleLabel(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return 'mosaedNotAvailableYet'.tr();
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = day.difference(today).inDays;
  final dayText = diff == 0
      ? 'mosaedToday'.tr()
      : diff == 1
          ? 'mosaedTomorrow'.tr()
          : DateFormat('d MMM', context.locale.toString()).format(dt);
  if (dt.hour == 0 && dt.minute == 0) return dayText;
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final period = dt.hour >= 12 ? 'م' : 'ص';
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$dayText، $hour:$mm $period';
}

String requestRelativeDayLabel(BuildContext context, String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return 'mosaedToday'.tr();
  final dt = DateTime.tryParse(createdAt)?.toLocal();
  if (dt == null) return 'mosaedToday'.tr();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'mosaedToday'.tr();
  if (diff == -1) return 'mosaedYesterday'.tr();
  return DateFormat('d MMM', context.locale.toString()).format(dt);
}

String requestOrderNumber(String id, {String prefix = 'INK'}) {
  if (id.length > 8) {
    return '$prefix-${id.substring(0, 8).toUpperCase()}';
  }
  return '$prefix-${id.toUpperCase()}';
}
