import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/caching/cach_helper.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _keys = <String, String>{
    'messages': 'notif_pref_messages',
    'opportunities': 'notif_pref_opportunities',
    'orders': 'notif_pref_orders',
    'appointments': 'notif_pref_appointments',
    'payments': 'notif_pref_payments',
  };

  final Map<String, bool> _values = {
    'messages': true,
    'opportunities': true,
    'orders': true,
    'appointments': true,
    'payments': true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final cache = CacheHelper();
    for (final entry in _keys.entries) {
      final stored = cache.getData(key: entry.value);
      if (stored is bool) {
        _values[entry.key] = stored;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _set(String key, bool value) async {
    setState(() => _values[key] = value);
    await CacheHelper().saveData(key: _keys[key]!, value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          'mosaedNotifications'.tr(),
          style: getMediumStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
        children: [
          _NotifSwitchTile(
            title: 'mosaedNotifMessages'.tr(),
            subtitle: 'mosaedNotifMessagesHint'.tr(),
            value: _values['messages']!,
            onChanged: (v) => _set('messages', v),
          ),
          SizedBox(height: 10.h),
          _NotifSwitchTile(
            title: 'mosaedNotifOpportunities'.tr(),
            subtitle: 'mosaedNotifOpportunitiesHint'.tr(),
            value: _values['opportunities']!,
            onChanged: (v) => _set('opportunities', v),
          ),
          SizedBox(height: 10.h),
          _NotifSwitchTile(
            title: 'mosaedNotifOrderStatus'.tr(),
            subtitle: 'mosaedNotifOrderStatusHint'.tr(),
            value: _values['orders']!,
            onChanged: (v) => _set('orders', v),
          ),
          SizedBox(height: 10.h),
          _NotifSwitchTile(
            title: 'mosaedNotifAppointments'.tr(),
            subtitle: 'mosaedNotifAppointmentsHint'.tr(),
            value: _values['appointments']!,
            onChanged: (v) => _set('appointments', v),
          ),
          SizedBox(height: 10.h),
          _NotifSwitchTile(
            title: 'mosaedNotifPayments'.tr(),
            subtitle: 'mosaedNotifPaymentsHint'.tr(),
            value: _values['payments']!,
            onChanged: (v) => _set('payments', v),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: MosaedColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: MosaedColors.brand,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'mosaedNotifSettingsHint'.tr(),
                    style: getRegularStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.brand,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifSwitchTile extends StatelessWidget {
  const _NotifSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getMediumStyle(
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
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Switch.adaptive(
            value: value,
            activeTrackColor: MosaedColors.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
