import '../../../services/data/models/address_models.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.avatar,
    this.gender,
    this.nationalId,
    this.commercialRegistration,
    this.specializationId,
    this.specializationName,
    required this.addresses,
    required this.isPhoneVerified,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? avatar;
  final String? gender;
  final String? nationalId;
  final String? commercialRegistration;
  final String? specializationId;
  final String? specializationName;
  final List<CustomerAddress> addresses;
  final bool isPhoneVerified;
  final String? createdAt;

  CustomerAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final addresses = json['addresses'] is List
        ? (json['addresses'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CustomerAddress.fromJson)
            .toList()
        : <CustomerAddress>[];

    final specialization = json['specialization'];
    final specializationMap =
        specialization is Map<String, dynamic> ? specialization : null;

    final rawPhoto = json['photo']?.toString() ??
        json['avatar']?.toString() ??
        json['image']?.toString() ??
        json['provider_image']?.toString() ??
        json['contract_image']?.toString();
    final photo = (rawPhoto == null ||
            rawPhoto.trim().isEmpty ||
            rawPhoto.toLowerCase() == 'null')
        ? null
        : rawPhoto.trim();

    return CustomerProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString(),
      avatar: photo,
      gender: json['gender']?.toString(),
      nationalId: json['national_id']?.toString(),
      commercialRegistration: json['commercial_registration']?.toString(),
      specializationId: specializationMap?['id']?.toString() ??
          json['specialization_id']?.toString() ??
          json['specialization']?.toString(),
      specializationName: specializationMap?['name']?.toString() ??
          json['specialization_name']?.toString(),
      addresses: addresses,
      isPhoneVerified: json['is_phone_verified'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}
