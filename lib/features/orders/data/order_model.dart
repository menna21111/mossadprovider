import 'package:flutter/material.dart';

import '../../../core/constants/mosaed_colors.dart';

enum OrderStatus {
  pending,
  workerArrived,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get statusKey {
    switch (this) {
      case OrderStatus.pending:
        return 'mosaedOrderPending';
      case OrderStatus.workerArrived:
        return 'mosaedOrderActive';
      case OrderStatus.completed:
        return 'mosaedOrderDone';
      case OrderStatus.cancelled:
        return 'mosaedOrderCancelled';
    }
  }

  Color get statusColor {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.workerArrived:
        return MosaedColors.primary;
      case OrderStatus.completed:
        return MosaedColors.success;
      case OrderStatus.cancelled:
        return MosaedColors.danger;
    }
  }

  bool get showArrival => this == OrderStatus.workerArrived;
  bool get showPaymentAndRating => this == OrderStatus.completed;
}

enum OrderType {
  booking,
  customRequest,
}

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    this.bookingId,
    required this.serviceTitle,
    this.serviceImage,
    required this.status,
    this.type = OrderType.booking,
    required this.workerName,
    required this.workerRating,
    required this.workerJobsCount,
    required this.agreedAmount,
    required this.paymentReceived,
    required this.scheduledSlot,
    required this.locationText,
    required this.arrivedAt,
    required this.finishedAt,
    required this.toolsUsed,
    required this.materialsUsed,
    required this.customerRating,
    required this.notes,
    this.paymentTime,
    this.complaintSubmitted = false,
    this.couponCode,
  });

  final String id;
  final String? bookingId;
  final String serviceTitle;
  final String? serviceImage;
  final OrderStatus status;
  final OrderType type;
  final String workerName;
  final double workerRating;
  final int workerJobsCount;
  final double agreedAmount;
  final bool paymentReceived;
  final String? paymentTime;
  final String scheduledSlot;
  final String locationText;
  final String arrivedAt;
  final String finishedAt;
  final List<String> toolsUsed;
  final List<String> materialsUsed;
  final double customerRating;
  final String notes;
  final bool complaintSubmitted;
  final String? couponCode;

  String get statusKey => status.statusKey;
  Color get statusColor => status.statusColor;

  bool get isCustomRequest => type == OrderType.customRequest;
  bool get isBooking => type == OrderType.booking;
  bool get isPending => status == OrderStatus.pending;
  bool get hasWorkerArrived => status == OrderStatus.workerArrived;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get needsRating => isCompleted && customerRating <= 0;
  bool get needsPayment => isCompleted && !paymentReceived;

  ServiceOrder copyWith({
    double? customerRating,
    bool? paymentReceived,
    String? paymentTime,
    bool? complaintSubmitted,
  }) {
    return ServiceOrder(
      id: id,
      bookingId: bookingId,
      serviceTitle: serviceTitle,
      serviceImage: serviceImage,
      status: status,
      type: type,
      workerName: workerName,
      workerRating: workerRating,
      workerJobsCount: workerJobsCount,
      agreedAmount: agreedAmount,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      paymentTime: paymentTime ?? this.paymentTime,
      scheduledSlot: scheduledSlot,
      locationText: locationText,
      arrivedAt: arrivedAt,
      finishedAt: finishedAt,
      toolsUsed: toolsUsed,
      materialsUsed: materialsUsed,
      customerRating: customerRating ?? this.customerRating,
      notes: notes,
      complaintSubmitted: complaintSubmitted ?? this.complaintSubmitted,
      couponCode: couponCode,
    );
  }
}
