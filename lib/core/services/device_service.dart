import 'dart:math';

import '../caching/cach_helper.dart';
import '../constants/app_constants.dart';

class DeviceService {
  DeviceService._();

  static Future<String> getDeviceId() async {
    final existing = CacheHelper().getDataString(key: AppConstants.deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = 'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
    await CacheHelper().saveData(key: AppConstants.deviceIdKey, value: id);
    return id;
  }
}
