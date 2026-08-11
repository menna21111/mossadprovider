import '../caching/cach_helper.dart';
import '../constants/app_constants.dart';

class UserLocation {
  const UserLocation({
    required this.city,
    required this.district,
    required this.street,
    this.details,
  });

  final String city;
  final String district;
  final String street;
  final String? details;

  String get fullAddress {
    final parts = [city, district, street];
    if (details != null && details!.trim().isNotEmpty) {
      parts.add(details!.trim());
    }
    return parts.join(' • ');
  }

  factory UserLocation.fromCache() {
    return UserLocation(
      city: CacheHelper().getDataString(key: AppConstants.userCityKey) ?? '',
      district:
          CacheHelper().getDataString(key: AppConstants.userDistrictKey) ?? '',
      street:
          CacheHelper().getDataString(key: AppConstants.userStreetKey) ?? '',
      details: CacheHelper().getDataString(key: AppConstants.userLocationDetailsKey),
    );
  }
}

class LocationService {
  LocationService._();

  static bool get isSetupDone =>
      CacheHelper().getData(key: AppConstants.locationSetupDoneKey) == true;

  static UserLocation get savedLocation => UserLocation.fromCache();

  static bool get hasValidLocation {
    final location = savedLocation;
    return location.city.isNotEmpty &&
        location.district.isNotEmpty &&
        location.street.isNotEmpty;
  }

  static Future<void> saveLocation(UserLocation location) async {
    await Future.wait([
      CacheHelper().saveData(key: AppConstants.userCityKey, value: location.city),
      CacheHelper().saveData(
        key: AppConstants.userDistrictKey,
        value: location.district,
      ),
      CacheHelper().saveData(
        key: AppConstants.userStreetKey,
        value: location.street,
      ),
      if (location.details != null && location.details!.isNotEmpty)
        CacheHelper().saveData(
          key: AppConstants.userLocationDetailsKey,
          value: location.details!,
        ),
      CacheHelper().saveData(key: AppConstants.locationSetupDoneKey, value: true),
    ]);
  }
}
