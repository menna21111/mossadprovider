class RegionModel {
  const RegionModel({
    required this.id,
    required this.name,
    required this.city,
    required this.isActive,
  });

  final String id;
  final String name;
  final String city;
  final bool isActive;

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}

class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.regions,
  });

  final String id;
  final String name;
  final bool isActive;
  final List<RegionModel> regions;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final regions = json['regions'] is List
        ? (json['regions'] as List)
            .whereType<Map<String, dynamic>>()
            .map(RegionModel.fromJson)
            .toList()
        : <RegionModel>[];

    return CityModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] == true,
      regions: regions,
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.city,
    required this.cityName,
    required this.region,
    required this.regionName,
    required this.district,
    required this.street,
    this.buildingNo,
    required this.lat,
    required this.lng,
    this.floorNo,
    this.apartmentNo,
    this.label,
    required this.isDefault,
  });

  final String id;
  final String city;
  final String cityName;
  final String region;
  final String regionName;
  final String district;
  final String street;
  final String? buildingNo;
  final String lat;
  final String lng;
  final String? floorNo;
  final String? apartmentNo;
  final String? label;
  final bool isDefault;

  String get fullAddress {
    final parts = [
      if (label != null && label!.isNotEmpty) label,
      cityName,
      regionName,
      district,
      street,
      if (buildingNo != null && buildingNo!.isNotEmpty) buildingNo,
    ];
    return parts.whereType<String>().join(' • ');
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      cityName: json['city_name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      regionName: json['region_name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      buildingNo: json['building_no']?.toString(),
      lat: json['lat']?.toString() ?? '0',
      lng: json['lng']?.toString() ?? '0',
      floorNo: json['floor_no']?.toString(),
      apartmentNo: json['apartment_no']?.toString(),
      label: json['label']?.toString(),
      isDefault: json['is_default'] == true,
    );
  }
}

class CreateAddressPayload {
  const CreateAddressPayload({
    required this.city,
    required this.region,
    required this.district,
    required this.street,
    this.buildingNo,
    this.floorNo,
    this.apartmentNo,
    required this.lat,
    required this.lng,
    this.label,
    this.isDefault = true,
  });

  final String city;
  final String region;
  final String district;
  final String street;
  final String? buildingNo;
  final String? floorNo;
  final String? apartmentNo;
  final double lat;
  final double lng;
  final String? label;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'city': city,
        'region': region,
        'district': district,
        'street': street,
        if (buildingNo != null && buildingNo!.isNotEmpty)
          'building_no': buildingNo,
        if (floorNo != null && floorNo!.isNotEmpty) 'floor_no': floorNo,
        if (apartmentNo != null && apartmentNo!.isNotEmpty)
          'apartment_no': apartmentNo,
        'lat': lat,
        'lng': lng,
        if (label != null && label!.isNotEmpty) 'label': label,
        'is_default': isDefault,
      };
}

class BookingItemPayload {
  const BookingItemPayload({
    required this.attributeId,
    required this.value,
  });

  final String attributeId;
  final num value;

  Map<String, dynamic> toJson() => {
        'attribute_id': attributeId,
        'value': value,
      };
}

class CreateBookingPayload {
  const CreateBookingPayload({
    required this.serviceId,
    this.providerId,
    required this.scheduledDate,
    this.notes,
    this.couponCode,
    required this.addressId,
    required this.items,
  });

  final String serviceId;
  final String? providerId;
  final String scheduledDate;
  final String? notes;
  final String? couponCode;
  final String addressId;
  final List<BookingItemPayload> items;

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        if (providerId != null && providerId!.isNotEmpty)
          'provider_id': providerId,
        'scheduled_date': scheduledDate,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (couponCode != null && couponCode!.isNotEmpty)
          'coupon_code': couponCode,
        'address_id': addressId,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
