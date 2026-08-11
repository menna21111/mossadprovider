import '../../../services/data/models/address_models.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.addresses,
    required this.isPhoneVerified,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
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

    return CustomerProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString(),
      addresses: addresses,
      isPhoneVerified: json['is_phone_verified'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}
