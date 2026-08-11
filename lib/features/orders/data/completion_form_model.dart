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
    this.finishedAt,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.paymentRequestId,
    this.paymentStatus,
  });

  final String id;

  /// Booking id أو custom request id حسب [kind].
  final String bookingId;
  final CompletionFormKind kind;
  final bool isFinished;
  final List<CompletionFormMedia> media;
  final PreviousWork? previousWork;
  final String? serviceTitle;
  final String? finishedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? paymentRequestId;
  final String? paymentStatus;

  bool get isCustomRequest => kind == CompletionFormKind.customRequest;
  String get workId => bookingId.isNotEmpty ? bookingId : id;

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

  bool get workNotStarted => !hasBeforeImage;

  /// قبل موجودة — لسه محتاجة رفع بعد (PATCH)
  bool get needsAfterUpload => hasBeforeImage && !hasRealAfterImage;

  /// قبل + بعد حقيقية + لسه مش finished
  bool get readyToFinish => hasBeforeImage && hasRealAfterImage && !isFinished;

  OrderStatus get status {
    if (isFinished) return OrderStatus.completed;
    if (hasBeforeImage) return OrderStatus.workerArrived;
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
    final previousWorkRaw = json['previous_work'];
    if (previousWorkRaw is Map<String, dynamic>) {
      previousWork = PreviousWork.fromJson(previousWorkRaw);
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

    return CompletionForm(
      id: json['id']?.toString() ?? '',
      bookingId: workId,
      kind: resolvedKind,
      serviceTitle: json['service_title']?.toString() ??
          json['request_title']?.toString() ??
          json['title']?.toString(),
      isFinished: json['is_finished'] == true,
      finishedAt: json['finished_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: json['notes']?.toString(),
      media: media,
      previousWork: previousWork,
      paymentRequestId: json['payment_request_id']?.toString() ??
          payment?['id']?.toString(),
      paymentStatus: json['payment_status']?.toString() ??
          payment?['status']?.toString(),
    );
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
  }) {
    return CompletionForm(
      id: id,
      bookingId: bookingId,
      kind: kind ?? this.kind,
      serviceTitle: serviceTitle,
      isFinished: isFinished ?? this.isFinished,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes ?? this.notes,
      media: media ?? this.media,
      previousWork: previousWork ?? this.previousWork,
      paymentRequestId: paymentRequestId ?? this.paymentRequestId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
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
      serviceImage: beforeImage ?? afterImage,
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
      arrivedAt: hasBeforeImage
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
