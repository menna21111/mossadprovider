import 'package:flutter/material.dart';

class ExistedService {
  const ExistedService({
    required this.id,
    required this.title,
    this.image,
    this.date,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? image;
  final String? date;
  final bool isActive;

  factory ExistedService.fromJson(Map<String, dynamic> json) {
    return ExistedService(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString(),
      date: json['date']?.toString(),
      isActive: json['is_active'] == true,
    );
  }

  bool get hasImage =>
      image != null && image!.trim().isNotEmpty && image!.toLowerCase() != 'null';

  IconData get icon {
    final t = title.toLowerCase();
    if (t.contains('سباكة') || t.contains('plumb')) {
      return Icons.plumbing_rounded;
    }
    if (t.contains('عزل') || t.contains('insul')) {
      return Icons.roofing_rounded;
    }
    if (t.contains('كهرب') || t.contains('electr')) {
      return Icons.electrical_services_rounded;
    }
    if (t.contains('تكييف') || t.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (t.contains('تنظيف') || t.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    if (t.contains('دهان') || t.contains('paint')) {
      return Icons.format_paint_rounded;
    }
    return Icons.home_repair_service_rounded;
  }

  Color get accentColor {
    final t = title.toLowerCase();
    if (t.contains('سباكة')) return const Color(0xFF3B82F6);
    if (t.contains('عزل')) return const Color(0xFF8B5CF6);
    if (t.contains('كهرب')) return const Color(0xFFF59E0B);
    if (t.contains('تكييف')) return const Color(0xFF06B6D4);
    if (t.contains('تنظيف')) return const Color(0xFF10B981);
    if (t.contains('دهان')) return const Color(0xFFEC4899);
    return const Color(0xFFE07A3A);
  }
}

class ServiceAttribute {
  const ServiceAttribute({
    required this.id,
    required this.name,
    this.details,
    required this.unitCost,
    this.unitName,
    this.quantityName,
  });

  final String id;
  final String name;
  final String? details;
  final String unitCost;
  final String? unitName;
  final String? quantityName;

  factory ServiceAttribute.fromJson(Map<String, dynamic> json) {
    return ServiceAttribute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      details: json['details']?.toString(),
      unitCost: json['unit_cost']?.toString() ?? '0',
      unitName: json['unit_name']?.toString(),
      quantityName: json['quantity_name']?.toString(),
    );
  }

  bool get hasUnitName => unitName != null && unitName!.trim().isNotEmpty;

  String unitLabel(String currency) {
    if (hasUnitName) return unitName!.trim();
    return currency;
  }

  String requiredFieldLabel(String fallback) {
    if (quantityName != null && quantityName!.trim().isNotEmpty) {
      return quantityName!.trim();
    }
    return fallback;
  }
}

class ServiceWarranty {
  const ServiceWarranty({
    required this.id,
    required this.durationValue,
    required this.durationType,
    this.notes,
  });

  final String id;
  final int durationValue;
  final String durationType;
  final String? notes;

  factory ServiceWarranty.fromJson(Map<String, dynamic> json) {
    return ServiceWarranty(
      id: json['id']?.toString() ?? '',
      durationValue: int.tryParse(json['duration_value']?.toString() ?? '') ?? 0,
      durationType: json['duration_type']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}

class ExistedServiceDetail extends ExistedService {
  const ExistedServiceDetail({
    required super.id,
    required super.title,
    super.image,
    super.date,
    required super.isActive,
    this.details,
    required this.attributes,
    this.warranty,
    this.visitCost,
  });

  final String? details;
  final List<ServiceAttribute> attributes;
  final ServiceWarranty? warranty;
  final String? visitCost;

  num? get visitCostValue => num.tryParse(visitCost ?? '');

  factory ExistedServiceDetail.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] is List
        ? (json['attributes'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ServiceAttribute.fromJson)
            .toList()
        : <ServiceAttribute>[];

    return ExistedServiceDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString(),
      date: json['date']?.toString(),
      isActive: json['is_active'] == true,
      details: json['details']?.toString(),
      attributes: attrs,
      warranty: json['warranty'] is Map<String, dynamic>
          ? ServiceWarranty.fromJson(json['warranty'] as Map<String, dynamic>)
          : null,
      visitCost: json['visit_cost']?.toString(),
    );
  }
}

class CouponValidationResult {
  const CouponValidationResult({
    required this.isValid,
    this.message,
    this.discountAmount,
    this.finalCost,
    this.originalCost,
  });

  final bool isValid;
  final String? message;
  final num? discountAmount;
  final num? finalCost;
  final num? originalCost;

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    final valid = json['valid'] == true ||
        json['is_valid'] == true ||
        json['success'] == true;

    num? readNum(dynamic v) {
      if (v == null) return null;
      return num.tryParse(v.toString());
    }

    return CouponValidationResult(
      isValid: valid,
      message: json['message']?.toString() ?? json['detail']?.toString(),
      discountAmount: readNum(
        json['discount_amount'] ?? json['discount'] ?? json['discount_value'],
      ),
      finalCost: readNum(
        json['final_cost'] ?? json['total_after_discount'] ?? json['new_total'],
      ),
      originalCost: readNum(json['original_cost'] ?? json['total_cost']),
    );
  }
}

class ServicePreviousWork {
  const ServicePreviousWork({
    required this.id,
    required this.beforeImage,
    required this.afterImage,
    this.createdAt,
  });

  final String id;
  final String beforeImage;
  final String afterImage;
  final String? createdAt;

  factory ServicePreviousWork.fromJson(Map<String, dynamic> json) {
    return ServicePreviousWork(
      id: json['id']?.toString() ?? '',
      beforeImage: json['before_image']?.toString() ?? '',
      afterImage: json['after_image']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    this.specializationName,
    this.imageUrl,
    required this.averageRating,
    required this.totalReviews,
    required this.isAvailable,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final String? specializationName;
  final String? imageUrl;
  final String averageRating;
  final int totalReviews;
  final bool isAvailable;

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final spec = json['specialization'] is Map<String, dynamic>
        ? json['specialization'] as Map<String, dynamic>
        : null;

    return ServiceProvider(
      id: json['id']?.toString() ?? '',
      providerId: json['provider_id']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      providerPhone: json['provider_phone']?.toString() ?? '',
      specializationName: spec?['name']?.toString(),
      imageUrl: json['provider_image']?.toString() ??
          json['image']?.toString() ??
          json['avatar']?.toString(),
      averageRating: json['average_rating']?.toString() ?? '0',
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '') ?? 0,
      isAvailable: json['is_available'] == true,
    );
  }
}
