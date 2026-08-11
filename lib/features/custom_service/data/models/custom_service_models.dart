import 'package:easy_localization/easy_localization.dart';

import '../../../orders/data/order_model.dart';

class Specialization {
  const Specialization({required this.id, required this.name});

  final String id;
  final String name;

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class CustomRequestPayload {
  const CustomRequestPayload({
    required this.specializationId,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.addressId,
    this.image,
  });

  final String specializationId;
  final String title;
  final String description;
  final String scheduledDate;
  final String addressId;
  final String? image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'specialization_id': specializationId,
      'title': title,
      'description': description,
      'scheduled_date': scheduledDate,
      "image": "https://res.cloudinary.com/dftpzis0y/image/upload/...",
      'address_id': addressId,

    };
    if (image != null && image!.trim().isNotEmpty) {
      map['image'] = image!.trim();
    }
    return map;
  }
}

class CustomRequest {
  const CustomRequest({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.rawStatus,
    required this.status,
    this.scheduledDate,
    this.specializationName,
    this.addressText,
    this.createdAt,
    this.offersCount,
  });

  final String id;
  final String title;
  final String description;
  final String? image;
  final String rawStatus;
  final OrderStatus status;
  final String? scheduledDate;
  final String? specializationName;
  final String? addressText;
  final String? createdAt;
  final int? offersCount;

  factory CustomRequest.fromJson(Map<String, dynamic> json) {
    final address = _asMap(json['address']);
    final rawStatus = json['status']?.toString() ?? '';
    final specialization = json['specialization'];
    final specializationMap = _asMap(specialization);

    return CustomRequest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      rawStatus: rawStatus,
      status: _mapStatus(rawStatus),
      scheduledDate: json['scheduled_date']?.toString(),
      specializationName: specialization is String
          ? specialization
          : specializationMap?['name']?.toString() ??
              json['specialization_id']?.toString(),
      addressText: _formatAddress(address, json),
      createdAt: json['created_at']?.toString(),
      offersCount: int.tryParse(
        json['offers_count']?.toString() ?? json['quotes_count']?.toString() ?? '',
      ),
    );
  }

  ServiceOrder toServiceOrder() {
    final shortId = id.length > 8 ? '#${id.substring(0, 8)}' : '#$id';

    return ServiceOrder(
      id: shortId,
      bookingId: id,
      serviceTitle: title.isNotEmpty ? title : 'mosaedCustomServiceTitle'.tr(),
      serviceImage: image,
      status: status,
      type: OrderType.customRequest,
      workerName: specializationName?.trim().isNotEmpty == true
          ? specializationName!
          : 'mosaedCustomRequestPending',
      workerRating: 0,
      workerJobsCount: offersCount ?? 0,
      agreedAmount: 0,
      paymentReceived: false,
      scheduledSlot: scheduledDate != null
          ? _formatDate(scheduledDate!)
          : 'mosaedNotAvailableYet',
      locationText: addressText?.trim().isNotEmpty == true
          ? addressText!
          : 'mosaedNotAvailableYet'.tr(),
      arrivedAt: 'mosaedNotArrivedYet',
      finishedAt: 'mosaedNotFinishedYet',
      toolsUsed: const [],
      materialsUsed: const [],
      customerRating: 0,
      notes: description.trim().isNotEmpty ? description : 'mosaedNoNotes'.tr(),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static OrderStatus _mapStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('cancel')) return OrderStatus.cancelled;
    if (s.contains('complete') || s.contains('done') || s.contains('finish')) {
      return OrderStatus.completed;
    }
    if (s.contains('progress') ||
        s.contains('active') ||
        s.contains('accept') ||
        s.contains('assign')) {
      return OrderStatus.workerArrived;
    }
    return OrderStatus.pending;
  }

  static String _formatAddress(Map<String, dynamic>? address, Map<String, dynamic> json) {
    if (address != null) {
      final parts = <String>[
        if (address['city_name'] != null) address['city_name'].toString(),
        if (address['district'] != null) address['district'].toString(),
        if (address['street'] != null) address['street'].toString(),
        if (address['label'] != null) address['label'].toString(),
      ].where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' • ');
    }
    return json['address_text']?.toString() ?? '';
  }

  static String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}
