import 'package:easy_localization/easy_localization.dart';

import 'order_model.dart';
import 'provider_offer_model.dart';

class RequestSpecialization {
  const RequestSpecialization({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.providersCount,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final int? providersCount;

  factory RequestSpecialization.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RequestSpecialization(id: '', name: '');
    }
    return RequestSpecialization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] != false,
      providersCount: int.tryParse(json['providers_count']?.toString() ?? ''),
    );
  }
}

class ProviderCustomRequest {
  const ProviderCustomRequest({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.specialization,
    this.city,
    this.region,
    this.district,
    this.scheduledDate,
    required this.status,
    this.expiresAt,
    this.myOffer,
    this.customerName,
    this.customerAvatar,
    this.distanceKm,
    this.photoCount,
    this.images = const [],
    this.createdAt,
    this.lat,
    this.lng,
  });

  final String id;
  final String title;
  final String description;
  final String? image;
  final List<String> images;
  final RequestSpecialization specialization;
  final String? city;
  final String? region;
  final String? district;
  final String? scheduledDate;
  final String status;
  final String? expiresAt;
  final ProviderOffer? myOffer;
  final String? customerName;
  final String? customerAvatar;
  final double? distanceKm;
  final int? photoCount;
  final String? createdAt;
  final double? lat;
  final double? lng;

  String? get specializationName =>
      specialization.name.isNotEmpty ? specialization.name : null;

  String get displayDescription {
    final desc = description.trim();
    if (desc.isNotEmpty) return desc;
    return (specializationName ?? '').trim();
  }

  bool get hasMyOffer => myOffer != null;

  bool get hasCoords => lat != null && lng != null;

  ProviderCustomRequest copyWith({
    String? title,
    String? description,
    String? image,
    List<String>? images,
    String? city,
    String? region,
    String? district,
    String? scheduledDate,
    String? status,
    String? expiresAt,
    ProviderOffer? myOffer,
    String? customerName,
    String? customerAvatar,
    double? distanceKm,
    int? photoCount,
    String? createdAt,
    double? lat,
    double? lng,
  }) {
    return ProviderCustomRequest(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      images: images ?? this.images,
      specialization: specialization,
      city: city ?? this.city,
      region: region ?? this.region,
      district: district ?? this.district,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      myOffer: myOffer ?? this.myOffer,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      distanceKm: distanceKm ?? this.distanceKm,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  String get locationText {
    final cityPart = (city ?? '').trim();
    final districtPart = (district ?? '').trim();
    if (cityPart.isNotEmpty && districtPart.isNotEmpty) {
      final districtLabel = districtPart.startsWith('حي')
          ? districtPart
          : 'حي $districtPart';
      return '$cityPart، $districtLabel';
    }
    final parts = <String>[
      if (cityPart.isNotEmpty) cityPart,
      if (districtPart.isNotEmpty) districtPart,
      if (region != null && region!.isNotEmpty) region!,
    ];
    return parts.join('، ');
  }

  OrderStatus get orderStatus {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return OrderStatus.cancelled;
    if (s.contains('complete') || s.contains('done')) return OrderStatus.completed;
    if (s.contains('accept') || s.contains('assign') || s.contains('active')) {
      return OrderStatus.workerArrived;
    }
    return OrderStatus.pending;
  }

  factory ProviderCustomRequest.fromJson(Map<String, dynamic> json) {
    final specializationRaw = json['specialization'];
    final specialization = specializationRaw is Map<String, dynamic>
        ? RequestSpecialization.fromJson(specializationRaw)
        : RequestSpecialization(
            id: json['specialization_id']?.toString() ?? '',
            name: json['specialization_name']?.toString() ??
                json['specialization']?.toString() ??
                '',
          );

    final myOfferRaw = json['my_offer'];
    ProviderOffer? myOffer;
    final myOfferMap = _asStringKeyedMap(myOfferRaw);
    if (myOfferMap != null) {
      myOffer = ProviderOffer.fromJson(myOfferMap);
    }

    final customerMap = _asStringKeyedMap(json['customer']);
    final images = json['images'];
    final imageUrls = _parseImageUrls(images);
    final photoCount = imageUrls.isNotEmpty
        ? imageUrls.length
        : int.tryParse(
            (json['photos_count'] ?? json['images_count'] ?? '').toString(),
          );

    final address = _addressMap(json);
    final city = json['city']?.toString() ??
        address?['city_name']?.toString() ??
        address?['city']?.toString();
    final region = json['region']?.toString() ??
        address?['region_name']?.toString() ??
        address?['region']?.toString();
    final district = json['district']?.toString() ??
        address?['district']?.toString();

    return ProviderCustomRequest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString().trim().isNotEmpty == true
          ? json['image']?.toString()
          : (imageUrls.isNotEmpty ? imageUrls.first : null),
      specialization: specialization,
      city: city,
      region: region,
      district: district,
      scheduledDate: json['scheduled_date']?.toString(),
      status: json['status']?.toString() ?? 'published',
      expiresAt: json['expires_at']?.toString(),
      myOffer: myOffer,
      customerName: customerMap?['name']?.toString() ??
          json['customer_name']?.toString(),
      customerAvatar: customerMap?['photo']?.toString() ??
          customerMap?['avatar']?.toString() ??
          customerMap?['image']?.toString() ??
          json['customer_avatar']?.toString() ??
          json['customer_photo']?.toString(),
      distanceKm: double.tryParse(
        (json['distance_km'] ?? json['distance'] ?? '').toString(),
      ),
      photoCount: photoCount,
      images: imageUrls,
      createdAt: json['created_at']?.toString(),
      lat: _parseCoord(
        json['lat'] ?? address?['lat'] ?? json['latitude'],
      ),
      lng: _parseCoord(
        json['lng'] ?? address?['lng'] ?? json['longitude'],
      ),
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, nested) => MapEntry(key.toString(), nested));
    }
    return null;
  }

  static Map<String, dynamic>? _addressMap(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['customer_address'],
      json['address'],
      json['location'],
      json['property_address'],
    ];

    final customer = _asStringKeyedMap(json['customer']);
    if (customer != null) {
      candidates.addAll([
        customer['customer_address'],
        customer['address'],
        customer['default_address'],
      ]);
      final addresses = customer['addresses'];
      if (addresses is List && addresses.isNotEmpty) {
        candidates.add(addresses.first);
      }
    }

    final addresses = json['addresses'];
    if (addresses is List && addresses.isNotEmpty) {
      candidates.add(addresses.first);
    }

    for (final candidate in candidates) {
      final map = _asStringKeyedMap(candidate);
      if (map != null) return map;
    }
    return null;
  }

  static double? _parseCoord(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString().trim());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }

  static List<String> _parseImageUrls(dynamic images) {
    if (images is! List || images.isEmpty) return const [];
    final urls = <String>[];
    for (final item in images) {
      if (item is String && item.trim().isNotEmpty) {
        urls.add(item.trim());
      } else if (item is Map) {
        final url = (item['image'] ?? item['url'] ?? item['src'])
            ?.toString()
            .trim();
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }
    return urls;
  }

  ServiceOrder toServiceOrder() {
    final shortId = id.length > 8 ? '#${id.substring(0, 8)}' : '#$id';

    return ServiceOrder(
      id: shortId,
      bookingId: id,
      serviceTitle: title.isNotEmpty ? title : 'mosaedCustomServiceTitle'.tr(),
      serviceImage: image,
      status: orderStatus,
      type: OrderType.customRequest,
      workerName: specializationName ?? 'mosaedCustomRequestPending',
      workerRating: 0,
      workerJobsCount: 0,
      agreedAmount: myOffer?.displayPrice ?? 0,
      paymentReceived: false,
      scheduledSlot: scheduledDate ?? 'mosaedNotAvailableYet',
      locationText: locationText.isNotEmpty
          ? locationText
          : 'mosaedNotAvailableYet'.tr(),
      arrivedAt: 'mosaedNotArrivedYet',
      finishedAt: 'mosaedNotFinishedYet',
      toolsUsed: const [],
      materialsUsed: const [],
      customerRating: 0,
      notes: description.trim().isNotEmpty ? description : 'mosaedNoNotes'.tr(),
    );
  }
}
