import 'dynamic_json_model.dart';

class ProviderOffer {
  const ProviderOffer({
    required this.id,
    required this.providerPrice,
    this.finalPrice,
    this.note,
    this.status,
    this.isAccepted = false,
    this.customRequestId,
    this.customRequestTitle,
    this.customRequestDescription,
    this.customRequestImage,
    this.requestStatus,
    this.specializationName,
    this.customerName,
    this.city,
    this.region,
    this.district,
    this.scheduledDate,
    this.distanceKm,
    this.photoCount,
    this.createdAt,
    this.updatedAt,
    this.lat,
    this.lng,
  });

  final String id;
  final double providerPrice;
  final double? finalPrice;
  final String? note;
  final String? status;
  final bool isAccepted;
  final String? customRequestId;
  final String? customRequestTitle;
  final String? customRequestDescription;
  final String? customRequestImage;
  final String? requestStatus;
  final String? specializationName;
  final String? customerName;
  final String? city;
  final String? region;
  final String? district;
  final String? scheduledDate;
  final double? distanceKm;
  final int? photoCount;
  final String? createdAt;
  final String? updatedAt;
  final double? lat;
  final double? lng;

  bool get isPending =>
      !isAccepted &&
      (status == null || status!.toLowerCase() == 'pending');

  bool get isRejected {
    final s = (status ?? '').toLowerCase();
    return s.contains('reject') || s.contains('decline');
  }

  /// Provider can chat with the client once the offer is accepted.
  bool get canChat =>
      isAccepted &&
      customRequestId != null &&
      customRequestId!.trim().isNotEmpty;

  /// Prefer provider_price; fall back to final_price when API omits provider_price.
  double get displayPrice =>
      providerPrice > 0 ? providerPrice : (finalPrice ?? 0);

  String get locationText {
    final cityPart = (city ?? '').trim();
    final districtPart = (district ?? '').trim();
    final regionPart = (region ?? '').trim();

    if (cityPart.isNotEmpty && districtPart.isNotEmpty) {
      final districtLabel = districtPart.startsWith('حي')
          ? districtPart
          : 'حي $districtPart';
      return '$cityPart، $districtLabel';
    }

    if (cityPart.isNotEmpty && regionPart.isNotEmpty) {
      return '$cityPart، $regionPart';
    }

    final parts = <String>[
      if (cityPart.isNotEmpty) cityPart,
      if (districtPart.isNotEmpty) districtPart,
      if (regionPart.isNotEmpty) regionPart,
    ];
    return parts.join('، ');
  }

  factory ProviderOffer.fromJson(Map<String, dynamic> json) {
    final request = json['custom_request'];
    final requestMap = request is Map<String, dynamic> ? request : null;
    final customer = requestMap?['customer'] ?? json['customer'];
    final customerMap = customer is Map<String, dynamic> ? customer : null;
    final addressRaw = json['customer_address'] ??
        requestMap?['customer_address'] ??
        requestMap?['address'] ??
        json['address'];
    final address =
        addressRaw is Map<String, dynamic> ? addressRaw : null;

    final status = json['status']?.toString();
    final isAccepted = _toBool(json['is_accepted']) ||
        (status?.toLowerCase().contains('accept') ?? false);

    final parsedFinal = json['final_price'] != null
        ? _toDouble(json['final_price'])
        : null;
    final parsedProvider = _toDouble(
      json['provider_price'] ?? json['price'] ?? json['final_price'],
    );

    final images = requestMap?['images'] ?? json['images'];
    final imageUrls = _parseImageUrls(images);
    final photoCount = imageUrls.isNotEmpty
        ? imageUrls.length
        : int.tryParse(
            (json['photos_count'] ??
                    json['images_count'] ??
                    requestMap?['photos_count'] ??
                    '')
                .toString(),
          );

    final directImage = requestMap?['image']?.toString() ??
        json['image']?.toString();

    return ProviderOffer(
      id: json['id']?.toString() ?? '',
      providerPrice: parsedProvider,
      finalPrice: parsedFinal,
      note: json['note']?.toString(),
      status: status,
      isAccepted: isAccepted,
      customRequestId: requestMap?['id']?.toString() ??
          json['request_id']?.toString() ??
          json['custom_request_id']?.toString(),
      customRequestTitle: requestMap?['title']?.toString() ??
          json['request_title']?.toString() ??
          json['custom_request_title']?.toString(),
      customRequestDescription: requestMap?['description']?.toString() ??
          json['description']?.toString() ??
          json['note']?.toString(),
      customRequestImage: (directImage != null && directImage.trim().isNotEmpty)
          ? directImage
          : (imageUrls.isNotEmpty ? imageUrls.first : null),
      requestStatus: json['request_status']?.toString() ??
          requestMap?['status']?.toString(),
      specializationName: json['specialization_name']?.toString() ??
          requestMap?['specialization_name']?.toString(),
      customerName: customerMap?['name']?.toString() ??
          json['customer_name']?.toString() ??
          requestMap?['customer_name']?.toString(),
      city: json['city']?.toString() ??
          address?['city_name']?.toString() ??
          address?['city']?.toString() ??
          requestMap?['city']?.toString(),
      region: json['region']?.toString() ??
          address?['region_name']?.toString() ??
          address?['region']?.toString() ??
          requestMap?['region']?.toString(),
      district: json['district']?.toString() ??
          address?['district']?.toString() ??
          requestMap?['district']?.toString(),
      scheduledDate: json['scheduled_date']?.toString() ??
          requestMap?['scheduled_date']?.toString(),
      distanceKm: _toDoubleOrNull(
        json['distance_km'] ??
            json['distance'] ??
            requestMap?['distance_km'] ??
            requestMap?['distance'],
      ),
      photoCount: photoCount,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      lat: _toDoubleOrNull(
        json['lat'] ?? address?['lat'] ?? requestMap?['lat'],
      ),
      lng: _toDoubleOrNull(
        json['lng'] ?? address?['lng'] ?? requestMap?['lng'],
      ),
    );
  }

  static double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString().trim());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }

  static bool _toBool(dynamic value) {
    if (value == true) return true;
    if (value == false) return false;
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes';
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
}

class SubmitOfferPayload {
  const SubmitOfferPayload({
    required this.providerPrice,
    required this.note,
  });

  final double providerPrice;
  final String note;

  Map<String, dynamic> toJson() => {
        'provider_price': providerPrice,
        'note': note,
      };
}

class ProviderOfferDetail extends DynamicJsonModel {
  const ProviderOfferDetail(super.raw);

  factory ProviderOfferDetail.fromJson(Map<String, dynamic> json) {
    return ProviderOfferDetail(Map<String, dynamic>.from(json));
  }

  String get id => string('id');

  double get providerPrice =>
      double.tryParse(
        string('provider_price', fallbacks: ['price', 'final_price']),
      ) ??
      0;

  double? get finalPrice {
    final value = string('final_price');
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  double get displayPrice =>
      providerPrice > 0 ? providerPrice : (finalPrice ?? 0);

  String? get note => _nullable(string('note'));

  String? get status => _nullable(string('status'));

  bool get isAccepted =>
      boolean('is_accepted') ||
      (status?.toLowerCase().contains('accept') ?? false);

  String? get customRequestId {
    final flat = string('request_id', fallbacks: ['custom_request_id']);
    if (flat.isNotEmpty) return flat;
    return _nullable(nestedString('custom_request', 'id'));
  }

  String? get customRequestTitle {
    final flat =
        string('request_title', fallbacks: ['custom_request_title']);
    if (flat.isNotEmpty) return flat;
    return _nullable(nestedString('custom_request', 'title'));
  }

  String? get requestStatus => _nullable(string('request_status'));

  String? get specializationName =>
      _nullable(string('specialization_name'));

  String? get city => _nullable(string('city'));

  String? get region => _nullable(string('region'));

  String get locationText {
    final parts = <String>[
      if (city != null) city!,
      if (region != null) region!,
    ];
    return parts.join(' • ');
  }

  bool get canChat =>
      isAccepted &&
      customRequestId != null &&
      customRequestId!.trim().isNotEmpty;

  static String? _nullable(String value) =>
      value.trim().isEmpty ? null : value.trim();
}
