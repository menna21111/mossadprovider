import 'package:easy_localization/easy_localization.dart';

import 'order_model.dart';

class BookingItem {
  const BookingItem({
    required this.attributeId,
    required this.attributeName,
    required this.value,
    this.unitCost,
  });

  final String attributeId;
  final String attributeName;
  final num value;
  final num? unitCost;

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final attr = json['attribute'];
    final attrMap = attr is Map<String, dynamic> ? attr : null;
    return BookingItem(
      attributeId: json['attribute_id']?.toString() ??
          attrMap?['id']?.toString() ??
          '',
      attributeName: attrMap?['name']?.toString() ??
          json['attribute_name']?.toString() ??
          '',
      value: num.tryParse(json['value']?.toString() ?? '') ?? 0,
      unitCost: num.tryParse(
        attrMap?['unit_cost']?.toString() ??
            json['unit_cost']?.toString() ??
            '',
      ),
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.serviceTitle,
    this.serviceImage,
    required this.rawStatus,
    required this.status,
    this.scheduledDate,
    this.createdAt,
    this.notes,
    required this.totalCost,
    required this.paymentReceived,
    this.paymentTime,
    this.paymentRequestId,
    this.paymentStatus,
    this.customerName,
    this.customerPhone,
    this.customerAvatar,
    this.providerName,
    required this.providerRating,
    required this.providerReviews,
    required this.addressText,
    this.lat,
    this.lng,
    this.arrivedAt,
    this.finishedAt,
    required this.items,
    required this.customerRating,
    required this.toolsUsed,
    required this.materialsUsed,
    this.couponCode,
  });

  final String id;
  final String serviceTitle;
  final String? serviceImage;
  final String rawStatus;
  final OrderStatus status;
  final String? scheduledDate;
  final String? createdAt;
  final String? notes;
  final double totalCost;
  final bool paymentReceived;
  final String? paymentTime;
  final String? paymentRequestId;
  final String? paymentStatus;
  final String? customerName;
  final String? customerPhone;
  final String? customerAvatar;
  final String? providerName;
  final double providerRating;
  final int providerReviews;
  final String addressText;
  final double? lat;
  final double? lng;
  final String? arrivedAt;
  final String? finishedAt;
  final List<BookingItem> items;
  final double customerRating;
  final List<String> toolsUsed;
  final List<String> materialsUsed;
  final String? couponCode;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final service = _asMap(json['service']);
    final provider = _asMap(json['provider']);
    final address = _asMap(json['address']);
    final payment = _asMap(json['payment']) ??
        _asMap(json['payment_request']);

    final items = <BookingItem>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(BookingItem.fromJson(item));
        }
      }
    }

    final rawStatus = json['status']?.toString() ?? '';
    final status = _mapStatus(rawStatus, json);

    final arrivedRaw = json['arrived_at'] ??
        json['provider_arrived_at'] ??
        json['arrival_time'];
    final finishedRaw = json['finished_at'] ??
        json['completed_at'] ??
        json['finish_time'];

    final paymentRaw = json['payment_received_at'] ??
        json['paid_at'] ??
        json['payment_time'] ??
        payment?['paid_at'];

    final paymentStatus = json['payment_status']?.toString() ??
        payment?['status']?.toString();
    final paymentRequestId = json['payment_request_id']?.toString() ??
        payment?['id']?.toString();

    return Booking(
      id: json['id']?.toString() ?? '',
      serviceTitle: service?['title']?.toString() ??
          json['service_title']?.toString() ??
          json['title']?.toString() ??
          '',
      serviceImage: service?['image']?.toString() ?? json['service_image']?.toString(),
      rawStatus: rawStatus,
      status: status,
      scheduledDate: json['scheduled_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      notes: json['notes']?.toString(),
      totalCost: _toDouble(
        json['final_cost'] ?? json['total_cost'] ?? json['agreed_amount'],
      ),
      paymentReceived: _isPaid(json) || _isPaidStatus(paymentStatus),
      paymentTime: paymentRaw?.toString(),
      paymentRequestId: paymentRequestId,
      paymentStatus: paymentStatus,
      customerName: json['customer_name']?.toString() ??
          _asMap(json['customer'])?['name']?.toString(),
      customerPhone: json['customer_phone']?.toString() ??
          _asMap(json['customer'])?['phone']?.toString(),
      customerAvatar: json['customer_avatar']?.toString() ??
          _asMap(json['customer'])?['avatar']?.toString() ??
          _asMap(json['customer'])?['photo']?.toString() ??
          _asMap(json['customer'])?['image']?.toString(),
      providerName: provider?['provider_name']?.toString() ??
          provider?['name']?.toString() ??
          json['provider_name']?.toString(),
      providerRating: _toDouble(
        provider?['average_rating'] ?? json['provider_rating'],
      ),
      providerReviews: int.tryParse(
            provider?['total_reviews']?.toString() ??
                json['provider_reviews']?.toString() ??
                '0',
          ) ??
          0,
      addressText: _formatAddress(address, json),
      lat: _parseCoord(address?['lat'] ?? json['lat']),
      lng: _parseCoord(address?['lng'] ?? json['lng']),
      arrivedAt: arrivedRaw?.toString(),
      finishedAt: finishedRaw?.toString(),
      items: items,
      customerRating: _toDouble(json['customer_rating'] ?? json['rating']),
      toolsUsed: _stringList(json['tools_used']),
      materialsUsed: _stringList(json['materials_used']),
      couponCode: json['coupon_code']?.toString(),
    );
  }

  ServiceOrder toServiceOrder() {
    final shortId = id.length > 8 ? '#${id.substring(0, 8)}' : '#$id';

    return ServiceOrder(
      id: shortId,
      bookingId: id,
      serviceTitle: serviceTitle.isNotEmpty ? serviceTitle : 'mosaedService'.tr(),
      serviceImage: serviceImage,
      status: status,
      workerName: providerName?.trim().isNotEmpty == true
          ? providerName!
          : 'mosaedWorkerPending',
      workerRating: providerRating,
      workerJobsCount: providerReviews,
      agreedAmount: totalCost,
      paymentReceived: paymentReceived,
      paymentTime: paymentTime != null ? _formatDateTime(paymentTime!) : null,
      scheduledSlot: scheduledDate != null
          ? _formatDateTime(scheduledDate!)
          : 'mosaedNotAvailableYet',
      locationText: addressText.isNotEmpty
          ? addressText
          : 'mosaedNotAvailableYet'.tr(),
      arrivedAt: arrivedAt != null
          ? _formatDateTime(arrivedAt!)
          : 'mosaedNotArrivedYet',
      finishedAt: finishedAt != null
          ? _formatDateTime(finishedAt!)
          : 'mosaedNotFinishedYet',
      toolsUsed: toolsUsed,
      materialsUsed: materialsUsed,
      customerRating: customerRating,
      notes: notes?.trim().isNotEmpty == true ? notes! : 'mosaedNoNotes'.tr(),
      couponCode: couponCode,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseCoord(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString().trim());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }

  static bool _isPaid(Map<String, dynamic> json) {
    if (json['payment_received'] == true ||
        json['is_paid'] == true ||
        json['paid'] == true) {
      return true;
    }
    final status = json['payment_status']?.toString().toLowerCase() ?? '';
    return _isPaidStatus(status);
  }

  static bool _isPaidStatus(String? status) {
    final s = status?.toLowerCase().trim() ?? '';
    return s == 'paid' ||
        s == 'received' ||
        s == 'cash_confirmed' ||
        s == 'success' ||
        s == 'payment_received';
  }

  static OrderStatus _mapStatus(String raw, Map<String, dynamic> json) {
    final s = raw.toLowerCase().trim();
    if (s.contains('cancel')) return OrderStatus.cancelled;

    if (s.contains('complete') ||
        s.contains('done') ||
        s.contains('finish') ||
        json['finished_at'] != null ||
        json['completed_at'] != null) {
      return OrderStatus.completed;
    }

    if (s.contains('arriv') ||
        s.contains('progress') ||
        s.contains('active') ||
        s.contains('way') ||
        s.contains('start') ||
        json['arrived_at'] != null) {
      return OrderStatus.workerArrived;
    }

    return OrderStatus.pending;
  }

  static String _formatAddress(Map<String, dynamic>? address, Map<String, dynamic> json) {
    if (address != null) {
      final city = (address['city_name'] ?? address['city'])?.toString();
      final region = (address['region_name'] ?? address['region'])?.toString();
      final district = address['district']?.toString();
      final parts = <String>[
        if ((address['label']?.toString() ?? '').trim().isNotEmpty)
          address['label'].toString(),
        if ((city ?? '').trim().isNotEmpty) city!,
        if ((district ?? '').trim().isNotEmpty) district!,
        if ((region ?? '').trim().isNotEmpty) region!,
        if ((address['street']?.toString() ?? '').trim().isNotEmpty)
          address['street'].toString(),
        if ((address['building_no']?.toString() ?? '').trim().isNotEmpty)
          'مبنى ${address['building_no']}',
        if ((address['floor_no']?.toString() ?? '').trim().isNotEmpty)
          'دور ${address['floor_no']}',
        if ((address['apartment_no']?.toString() ?? '').trim().isNotEmpty)
          'شقة ${address['apartment_no']}',
      ];
      if (parts.isNotEmpty) return parts.join(' • ');
    }
    return json['address_text']?.toString() ?? '';
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd • HH:mm').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}
