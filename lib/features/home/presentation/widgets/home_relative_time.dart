import 'package:easy_localization/easy_localization.dart';

String homeRelativeTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final date = DateTime.tryParse(raw);
  if (date == null) return '';
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'mosaedJustNow'.tr();
  if (diff.inMinutes < 60) {
    return 'mosaedMinutesAgo'.tr(args: ['${diff.inMinutes}']);
  }
  if (diff.inHours < 24) {
    return 'mosaedHoursAgo'.tr(args: ['${diff.inHours}']);
  }
  return 'mosaedDaysAgo'.tr(args: ['${diff.inDays}']);
}
