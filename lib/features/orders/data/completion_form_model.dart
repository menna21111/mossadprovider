import 'package:easy_localization/easy_localization.dart';

import 'order_model.dart';

enum CompletionFormKind {
  booking,
  customRequest,
}

class CompletionFormMedia {
  const CompletionFormMedia({
    required this.url,
    this.type,
    this.id,
  });

  final String url;
  final String? type;
  final String? id;

  bool get isBefore {
    final t = (type ?? '').toLowerCase();
    return t.contains('before') || t.contains('قبل');
  }

  bool get isAfter {
    final t = (type ?? '').toLowerCase();
    return t.contains('after') || t.contains('بعد');
  }

  factory CompletionFormMedia.fromJson(dynamic raw) {
    if (raw is String) {
      return CompletionFormMedia(url: raw);
    }
    if (raw is Map<String, dynamic>) {
      return CompletionFormMedia(
        id: raw['id']?.toString(),
        type: raw['type']?.toString() ??
            raw['kind']?.toString() ??
            raw['media_type']?.toString(),
        url: raw['url']?.toString() ??
            raw['image']?.toString() ??
            raw['file']?.toString() ??
            raw['before_image']?.toString() ??
            raw['after_image']?.toString() ??
            '',
      );
    }
    return const CompletionFormMedia(url: '');
  }
}

class PreviousWork {
  const PreviousWork({
    this.id,
    this.beforeImage,
    this.afterImage,
    this.createdAt,
  });

  final String? id;
  final String? beforeImage;
  final String? afterImage;
  final String? createdAt;

  bool get hasBefore =>
      beforeImage != null && beforeImage!.trim().isNotEmpty;

  bool get hasAfter => afterImage != null && afterImage!.trim().isNotEmpty;

  factory PreviousWork.fromJson(Map<String, dynamic> json) {
    return PreviousWork(
      id: json['id']?.toString(),
      beforeImage: _nullableUrl(json['before_image']),
      afterImage: _nullableUrl(json['after_image']),
      createdAt: json['created_at']?.toString(),
    );
  }

  static String? _nullableUrl(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}

class CompletionForm {
  const CompletionForm({
    required this.id,
    required this.bookingId,
    required this.isFinished,
    required this.media,
    this.kind = CompletionFormKind.booking,
    this.previousWork,
    this.serviceTitle,
    this.specializationName,
    this.apiStatus,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.paymentRequestId,
    this.paymentStatus,
    this.finalPrice,
    this.customerName,
    this.customerAvatar,
    this.customerPhone,
    this.city,
    this.region,
    this.district,
    this.street,
    this.scheduledDate,
    this.description,
    this.lat,
    this.lng,
    this.requestImages = const [],
    this.serviceImage,
  });

  final String id;

  /// Booking id أو custom request id حسب [kind].
  final String bookingId;
  final CompletionFormKind kind;
  final bool isFinished;
  final List<CompletionFormMedia> media;
  final PreviousWork? previousWork;
  final String? serviceTitle;
  final String? specializationName;

  /// Raw API status e.g. `provider_arrived`, `waiting`.
  final String? apiStatus;

  /// Non-null → provider arrived / execution unlocked (can upload photos).
  final String? startedAt;
  final String? finishedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? paymentRequestId;
  final String? paymentStatus;
  final double? finalPrice;
  final String? customerName;
  final String? customerAvatar;
  final String? customerPhone;
  final String? city;
  final String? region;
  final String? district;
  final String? street;
  final String? scheduledDate;
  final String? description;
  final double? lat;
  final double? lng;

  /// Problem photos from the custom request (not work before/after).
  final List<String> requestImages;

  /// Catalog / booking cover for existed services.
  final String? serviceImage;

  bool get isCustomRequest => kind == CompletionFormKind.customRequest;
  String get workId => bookingId.isNotEmpty ? bookingId : id;

  String get displayTitle {
    final title = (serviceTitle ?? '').trim();
    if (title.isNotEmpty) return title;
    final spec = (specializationName ?? '').trim();
    if (spec.isNotEmpty) return spec;
    return isCustomRequest
        ? 'mosaedCustomRequest'.tr()
        : 'mosaedActiveJob'.tr();
  }

  String? get cardImage {
    if (requestImages.isNotEmpty) return requestImages.first;
    final service = (serviceImage ?? '').trim();
    if (service.isNotEmpty) return service;
    return beforeImage;
  }

  /// In-progress, or finished but the customer still hasn't paid.
  bool get isCurrentWork => !isFinished || isPaymentPending;

  int get cardPhotoCount {
    if (requestImages.isNotEmpty) return requestImages.length;
    return photoCount;
  }

  String get displayCustomerName {
    final name = (customerName ?? '').trim();
    if (name.isNotEmpty) return name;
    return 'mosaedClient'.tr();
  }

  /// `started_at != null` (or arrived status) → وصل ويقدر يرفع الصور.
  bool get hasArrived {
    final started = startedAt?.trim() ?? '';
    if (started.isNotEmpty && started.toLowerCase() != 'null') return true;
    final s = (apiStatus ?? '').toLowerCase().trim();
    return s == 'provider_arrived' || s.contains('arrived');
  }

  bool get needsArrival => !isFinished && !hasArrived;

  int get photoCount {
    final count = media.where((m) => m.url.trim().isNotEmpty).length;
    if (count > 0) return count;
    var n = 0;
    if (hasBeforeImage) n++;
    if (hasRealAfterImage) n++;
    return n;
  }

  String get locationText {
    final cityPart = (city ?? '').trim();
    final districtPart = (district ?? '').trim();
    final streetPart = (street ?? '').trim();
    if (cityPart.isNotEmpty && districtPart.isNotEmpty) {
      final districtLabel = districtPart.startsWith('حي')
          ? districtPart
          : 'حي $districtPart';
      if (streetPart.isNotEmpty) {
        return '$cityPart، $districtLabel، $streetPart';
      }
      return '$cityPart، $districtLabel';
    }
    final parts = <String>[
      if (cityPart.isNotEmpty) cityPart,
      if (districtPart.isNotEmpty) districtPart,
      if ((region ?? '').trim().isNotEmpty) region!.trim(),
      if (streetPart.isNotEmpty) streetPart,
    ];
    return parts.join('، ');
  }

  String get displayDescription {
    final note = (notes ?? '').trim();
    if (note.isNotEmpty) return note;
    final desc = (description ?? '').trim();
    if (desc.isNotEmpty) return desc;
    final spec = (specializationName ?? '').trim();
    if (spec.isNotEmpty && spec != (serviceTitle ?? '').trim()) return spec;
    if (isFinished) return '';
    return 'mosaedJobInProgressHint'.tr();
  }

  bool get awaitingCashConfirmation {
    final status = paymentStatus?.toLowerCase().trim() ?? '';
    return status == 'awaiting_cash_confirmation';
  }

  bool get awaitingPaymentMethod {
    final status = paymentStatus?.toLowerCase().trim() ?? '';
    return status == 'awaiting_method';
  }

  bool get awaitingGatewayPayment {
    final status = paymentStatus?.toLowerCase().trim() ?? '';
    return status == 'awaiting_gateway_payment' ||
        status == 'awaiting_online_payment' ||
        status == 'pending_payment';
  }

  bool get paymentConfirmed {
    final status = paymentStatus?.toLowerCase().trim() ?? '';
    // Do NOT treat generic "completed" as paid — that is the job/booking status.
    return status == 'paid' ||
        status == 'cash_confirmed' ||
        status == 'received' ||
        status == 'success' ||
        status == 'payment_received';
  }

  bool get hasPaymentRequest {
    final id = paymentRequestId?.trim() ?? '';
    return id.isNotEmpty && id.toLowerCase() != 'null';
  }

  /// Payment still open — customer hasn't paid / provider hasn't confirmed cash.
  bool get isPaymentPending {
    if (paymentConfirmed) return false;
    if (awaitingPaymentMethod ||
        awaitingCashConfirmation ||
        awaitingGatewayPayment) {
      return true;
    }
    if (hasPaymentRequest &&
        (paymentStatus == null || paymentStatus!.trim().isEmpty)) {
      return true;
    }
    final status = paymentStatus?.toLowerCase().trim() ?? '';
    if (status.isEmpty) return false;
    // Any known non-paid payment status counts as pending.
    return status.contains('await') ||
        status.contains('pend') ||
        status == 'unpaid' ||
        status == 'created';
  }

  String get paymentStatusLabelKey {
    if (paymentConfirmed) return 'mosaedPaymentReceived';
    if (awaitingCashConfirmation) return 'mosaedAwaitingCashConfirmation';
    if (awaitingGatewayPayment) return 'mosaedAwaitingGatewayPayment';
    if (awaitingPaymentMethod) return 'mosaedAwaitingPaymentMethod';
    if (isPaymentPending) return 'mosaedPaymentPending';
    return 'mosaedPaymentPending';
  }

  static const fixedBeforeImage =
      'https://res.cloudinary.com/demo/image/upload/before.jpg';
  static const fixedAfterImage =
      'https://res.cloudinary.com/demo/image/upload/after.jpg';
  static const fixedAfterImageV2 =
      'https://res.cloudinary.com/demo/image/upload/after_v2.jpg';

  static bool isPlaceholderAfterUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final normalized = url.trim();
    return normalized == fixedAfterImage || normalized == fixedAfterImageV2;
  }

  static bool isPlaceholderBeforeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    return url.trim() == fixedBeforeImage;
  }

  bool get mediaEmpty => !hasBeforeImage;

  bool get hasOneMedia => hasBeforeImage && !hasAfterImage;

  bool get hasTwoMedia => hasBothPreviousWorkImages;

  String? get beforeImage {
    final fromPrevious = previousWork?.beforeImage;
    if (fromPrevious != null && fromPrevious.trim().isNotEmpty) {
      return fromPrevious;
    }

    for (final item in media) {
      if (item.isBefore && item.url.isNotEmpty) return item.url;
    }
    if (media.isNotEmpty && media.first.url.isNotEmpty) {
      return media.first.url;
    }
    return null;
  }

  String? get afterImage {
    final fromPrevious = previousWork?.afterImage;
    if (fromPrevious != null && fromPrevious.trim().isNotEmpty) {
      return fromPrevious;
    }

    for (final item in media) {
      if (item.isAfter && item.url.isNotEmpty) return item.url;
    }
    if (media.length >= 2 && media[1].url.isNotEmpty) {
      return media[1].url;
    }
    return null;
  }

  bool get hasBeforeImage {
    final url = beforeImage;
    return url != null && url.trim().isNotEmpty;
  }

  bool get hasAfterImage {
    final url = afterImage;
    return url != null && url.trim().isNotEmpty;
  }

  bool get hasRealAfterImage =>
      hasAfterImage && !isPlaceholderAfterUrl(afterImage);

  bool get hasBothPreviousWorkImages =>
      previousWork?.hasBefore == true && previousWork?.hasAfter == true;

  /// لسه مفيش صورة قبل — حتى لو وصل (`started_at`).
  bool get workNotStarted => !hasBeforeImage;

  /// وصل ومسموح يرفع صور قبل.
  bool get canUploadBeforePhotos => hasArrived && !hasBeforeImage && !isFinished;

  /// قبل موجودة — لسه محتاجة رفع بعد (PATCH)
  bool get needsAfterUpload => hasBeforeImage && !hasRealAfterImage;

  /// قبل + بعد حقيقية + لسه مش finished
  bool get readyToFinish => hasBeforeImage && hasRealAfterImage && !isFinished;

  OrderStatus get status {
    if (isFinished) return OrderStatus.completed;
    if (hasArrived || hasBeforeImage) return OrderStatus.workerArrived;
    return OrderStatus.pending;
  }

  factory CompletionForm.fromJson(
    Map<String, dynamic> json, {
    CompletionFormKind? kind,
    String? preferredWorkId,
  }) {
    final mediaRaw = json['media'];
    final media = <CompletionFormMedia>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        final parsed = CompletionFormMedia.fromJson(item);
        if (parsed.url.trim().isNotEmpty) media.add(parsed);
      }
    }

    PreviousWork? previousWork;
    final previousWorkMap = _asStringKeyedMap(json['previous_work']);
    if (previousWorkMap != null) {
      previousWork = PreviousWork.fromJson(previousWorkMap);
    }

    final payment = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : json['payment_request'] is Map<String, dynamic>
            ? json['payment_request'] as Map<String, dynamic>
            : null;

    final requestId = json['request_id']?.toString() ??
        json['custom_request_id']?.toString();
    final bookingId = json['booking_id']?.toString();
    final resolvedKind = kind ??
        ((requestId != null &&
                requestId.isNotEmpty &&
                (bookingId == null || bookingId.isEmpty))
            ? CompletionFormKind.customRequest
            : CompletionFormKind.booking);

    final workId = preferredWorkId?.trim().isNotEmpty == true
        ? preferredWorkId!
        : resolvedKind == CompletionFormKind.customRequest
            ? (requestId?.isNotEmpty == true
                ? requestId!
                : (json['id']?.toString() ?? ''))
            : (bookingId?.isNotEmpty == true
                ? bookingId!
                : (json['id']?.toString() ?? ''));

    final customer = json['customer'];
    final customerMap = _asStringKeyedMap(customer);
    final request = json['request'] ?? json['custom_request'] ?? json['booking'];
    final requestMap = _asStringKeyedMap(request);
    final address = _asStringKeyedMap(
          json['customer_address'] ??
              json['address'] ??
              requestMap?['customer_address'] ??
              requestMap?['address'],
        ) ??
        _firstAddressMap(customerMap?['addresses'] ?? json['addresses']);

    final attribute = _firstServiceAttribute(json['service_attributes']);
    final attributeName = attribute?['name']?.toString().trim();
    final attributeDetails = attribute?['details']?.toString().trim();

    final requestImages = _parseImageUrls(
      json['custom_request_images'] ??
          json['request_images'] ??
          (resolvedKind == CompletionFormKind.customRequest
              ? (json['images'] ?? requestMap?['images'])
              : null),
    );

    final serviceMap = _asStringKeyedMap(json['service']);
    final serviceImage = _nullableText(
      serviceMap?['image']?.toString() ??
          serviceMap?['cover']?.toString() ??
          json['service_image']?.toString() ??
          json['cover_image']?.toString() ??
          (resolvedKind == CompletionFormKind.booking
              ? json['image']?.toString()
              : null),
    );

    return CompletionForm(
      id: json['id']?.toString() ?? '',
      bookingId: workId,
      kind: resolvedKind,
      serviceTitle: json['service_title']?.toString() ??
          json['request_title']?.toString() ??
          json['title']?.toString() ??
          requestMap?['title']?.toString() ??
          requestMap?['request_title']?.toString() ??
          (attributeName?.isNotEmpty == true ? attributeName : null),
      specializationName: json['specialization_name']?.toString() ??
          requestMap?['specialization_name']?.toString() ??
          json['service_name']?.toString() ??
          (attributeName?.isNotEmpty == true ? attributeName : null),
      isFinished: json['is_finished'] == true,
      apiStatus: json['status']?.toString(),
      startedAt: _nullableText(json['started_at']?.toString()),
      finishedAt: _nullableText(json['finished_at']?.toString()),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: json['notes']?.toString() ?? json['note']?.toString(),
      description: json['description']?.toString() ??
          requestMap?['description']?.toString() ??
          (attributeDetails?.isNotEmpty == true ? attributeDetails : null),
      media: media,
      previousWork: previousWork,
      paymentRequestId: json['payment_request_id']?.toString() ??
          payment?['id']?.toString(),
      paymentStatus: json['payment_status']?.toString() ??
          payment?['status']?.toString(),
      finalPrice: _toDouble(
        json['final_price'] ??
            json['price'] ??
            json['agreed_amount'] ??
            payment?['amount'],
      ),
      customerName: _nullableText(
        customerMap?['name']?.toString() ??
            json['customer_name']?.toString() ??
            requestMap?['customer_name']?.toString(),
      ),
      customerAvatar: _nullableText(
        customerMap?['photo']?.toString() ??
            customerMap?['avatar']?.toString() ??
            customerMap?['image']?.toString() ??
            json['customer_avatar']?.toString() ??
            json['customer_photo']?.toString(),
      ),
      customerPhone: _nullableText(
        customerMap?['phone_number']?.toString() ??
            customerMap?['phone']?.toString() ??
            json['customer_phone']?.toString(),
      ),
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
      street: json['street']?.toString() ??
          address?['street']?.toString() ??
          requestMap?['street']?.toString(),
      scheduledDate: json['scheduled_date']?.toString() ??
          requestMap?['scheduled_date']?.toString(),
      lat: parseCoord(
        json['lat'] ?? address?['lat'] ?? requestMap?['lat'],
      ),
      lng: parseCoord(
        json['lng'] ?? address?['lng'] ?? requestMap?['lng'],
      ),
      requestImages: requestImages,
      serviceImage: serviceImage,
    );
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

  static Map<String, dynamic>? _firstServiceAttribute(dynamic value) {
    if (value is! List || value.isEmpty) return null;
    return _asStringKeyedMap(value.first);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static String? _nullableText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, nested) => MapEntry(key.toString(), nested));
    }
    return null;
  }

  static Map<String, dynamic>? _firstAddressMap(dynamic value) {
    if (value is! List || value.isEmpty) return null;
    return _asStringKeyedMap(value.first);
  }

  static double? parseCoord(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString().trim());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }

  CompletionForm copyWith({
    bool? isFinished,
    String? finishedAt,
    String? notes,
    List<CompletionFormMedia>? media,
    PreviousWork? previousWork,
    CompletionFormKind? kind,
    String? paymentRequestId,
    String? paymentStatus,
    String? apiStatus,
    String? startedAt,
    String? serviceImage,
    List<String>? requestImages,
  }) {
    return CompletionForm(
      id: id,
      bookingId: bookingId,
      kind: kind ?? this.kind,
      serviceTitle: serviceTitle,
      specializationName: specializationName,
      isFinished: isFinished ?? this.isFinished,
      apiStatus: apiStatus ?? this.apiStatus,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes ?? this.notes,
      description: description,
      media: media ?? this.media,
      previousWork: previousWork ?? this.previousWork,
      paymentRequestId: paymentRequestId ?? this.paymentRequestId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      finalPrice: finalPrice,
      customerName: customerName,
      customerAvatar: customerAvatar,
      customerPhone: customerPhone,
      city: city,
      region: region,
      district: district,
      street: street,
      scheduledDate: scheduledDate,
      lat: lat,
      lng: lng,
      requestImages: requestImages ?? this.requestImages,
      serviceImage: serviceImage ?? this.serviceImage,
    );
  }

  ServiceOrder toServiceOrder() {
    final orderId = workId;
    final shortId =
        orderId.length > 8 ? '#${orderId.substring(0, 8)}' : '#$orderId';

    return ServiceOrder(
      id: shortId,
      bookingId: orderId,
      serviceTitle: serviceTitle?.isNotEmpty == true
          ? serviceTitle!
          : (isCustomRequest
              ? 'mosaedCustomRequest'.tr()
              : 'mosaedService'.tr()),
      serviceImage: cardImage ?? beforeImage ?? afterImage,
      status: status,
      type: isCustomRequest ? OrderType.customRequest : OrderType.booking,
      workerName: isCustomRequest
          ? 'mosaedCustomRequestBadge'.tr()
          : 'mosaedGuest'.tr(),
      workerRating: 0,
      workerJobsCount: 0,
      agreedAmount: 0,
      paymentReceived: paymentConfirmed,
      scheduledSlot: createdAt != null
          ? _formatDate(createdAt!)
          : 'mosaedNotAvailableYet',
      locationText: 'mosaedNotAvailableYet'.tr(),
      arrivedAt: hasArrived
          ? 'mosaedWorkStarted'.tr()
          : 'mosaedNotArrivedYet',
      finishedAt: isFinished
          ? (finishedAt != null
              ? _formatDate(finishedAt!)
              : 'mosaedOrderDone'.tr())
          : 'mosaedNotFinishedYet',
      toolsUsed: const [],
      materialsUsed: const [],
      customerRating: 0,
      notes: notes?.trim().isNotEmpty == true ? notes! : 'mosaedNoNotes'.tr(),
    );
  }

  static String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd • HH:mm').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}
