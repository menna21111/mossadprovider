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
    this.requestStatus,
    this.specializationName,
    this.city,
    this.region,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final double providerPrice;
  final double? finalPrice;
  final String? note;
  final String? status;
  final bool isAccepted;
  final String? customRequestId;
  final String? customRequestTitle;
  final String? requestStatus;
  final String? specializationName;
  final String? city;
  final String? region;
  final String? createdAt;
  final String? updatedAt;

  bool get isPending =>
      !isAccepted &&
      (status == null || status!.toLowerCase() == 'pending');

  /// Provider can chat with the client once the offer is accepted.
  bool get canChat =>
      isAccepted &&
      customRequestId != null &&
      customRequestId!.trim().isNotEmpty;

  /// Prefer provider_price; fall back to final_price when API omits provider_price.
  double get displayPrice =>
      providerPrice > 0 ? providerPrice : (finalPrice ?? 0);

  String get locationText {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (region != null && region!.isNotEmpty) region!,
    ];
    return parts.join(' • ');
  }

  factory ProviderOffer.fromJson(Map<String, dynamic> json) {
    final request = json['custom_request'];
    final requestMap = request is Map<String, dynamic> ? request : null;

    final status = json['status']?.toString();
    final isAccepted = _toBool(json['is_accepted']) ||
        (status?.toLowerCase().contains('accept') ?? false);

    final parsedFinal = json['final_price'] != null
        ? _toDouble(json['final_price'])
        : null;
    final parsedProvider = _toDouble(
      json['provider_price'] ?? json['price'] ?? json['final_price'],
    );

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
      requestStatus: json['request_status']?.toString() ??
          requestMap?['status']?.toString(),
      specializationName: json['specialization_name']?.toString() ??
          requestMap?['specialization_name']?.toString(),
      city: json['city']?.toString() ?? requestMap?['city']?.toString(),
      region: json['region']?.toString() ?? requestMap?['region']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static bool _toBool(dynamic value) {
    if (value == true) return true;
    if (value == false) return false;
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes';
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
