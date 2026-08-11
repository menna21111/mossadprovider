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
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? image;
  final RequestSpecialization specialization;
  final String? city;
  final String? region;
  final String? district;
  final String? scheduledDate;
  final String status;
  final String? expiresAt;
  final ProviderOffer? myOffer;
  final String? createdAt;

  String? get specializationName =>
      specialization.name.isNotEmpty ? specialization.name : null;

  bool get hasMyOffer => myOffer != null;

  String get locationText {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (region != null && region!.isNotEmpty) region!,
      if (district != null && district!.isNotEmpty) district!,
    ];
    return parts.join(' • ');
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
        : RequestSpecialization.fromJson(null);

    final myOfferRaw = json['my_offer'];
    ProviderOffer? myOffer;
    if (myOfferRaw is Map<String, dynamic>) {
      myOffer = ProviderOffer.fromJson(myOfferRaw);
    }

    return ProviderCustomRequest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      specialization: specialization,
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      district: json['district']?.toString(),
      scheduledDate: json['scheduled_date']?.toString(),
      status: json['status']?.toString() ?? 'published',
      expiresAt: json['expires_at']?.toString(),
      myOffer: myOffer,
      createdAt: json['created_at']?.toString(),
    );
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
