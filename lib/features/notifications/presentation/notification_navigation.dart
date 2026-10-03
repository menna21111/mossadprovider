import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../custom_service/presentation/custom_request_detail_screen.dart';
import '../../home/presentation/offer_detail_screen.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/presentation/task_detail_screen.dart';
import '../../payments/presentation/provider_dues_screen.dart';
import '../data/models/app_notification.dart';

class NotificationNavigation {
  NotificationNavigation._();

  static Future<void> open(
    BuildContext context,
    AppNotification notification,
  ) async {
    final screen = _screenFor(notification);
    if (screen == null) {
      AppFunctions.showsToast(
        'mosaedNotificationOpenFailed'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    await AppFunctions.navigateTo(
      context,
      screen,
      PageTransitionType.rightToLeft,
    );
  }

  static Widget? _screenFor(AppNotification notification) {
    final event = notification.event.toLowerCase().trim();
    final requestId = _nonEmpty(notification.requestId);
    final offerId = _nonEmpty(notification.offerId);
    final bookingId = _nonEmpty(notification.bookingId);
    final title = _nonEmpty(notification.requestTitle) ??
        _nonEmpty(notification.title);

    switch (event) {
      case 'new_chat_message':
        if (requestId == null) return null;
        return ChatScreen(
          requestId: requestId,
          requestTitle: title,
        );
      case 'new_custom_request':
        if (requestId == null) return null;
        return CustomRequestDetailScreen(requestId: requestId);
      case 'offer_accepted':
        if (requestId != null) {
          return CustomRequestDetailScreen(requestId: requestId);
        }
        if (offerId != null) {
          return OfferDetailScreen(offerId: offerId);
        }
        return null;
      case 'offer_rejected':
      case 'offer_cancelled':
      case 'new_offer':
        if (offerId != null) return OfferDetailScreen(offerId: offerId);
        if (requestId != null) {
          return CustomRequestDetailScreen(requestId: requestId);
        }
        return null;
      case 'due_payment_required':
        return const ProviderDuesScreen();
      case 'booking_assigned':
      case 'booking_status_changed':
      case 'new_booking':
        if (bookingId != null) {
          return TaskDetailScreen(
            workId: bookingId,
            kind: CompletionFormKind.booking,
            initialTitle: title,
          );
        }
        return null;
      default:
        if (bookingId != null) {
          return TaskDetailScreen(
            workId: bookingId,
            kind: CompletionFormKind.booking,
            initialTitle: title,
          );
        }
        if (requestId != null) {
          return CustomRequestDetailScreen(requestId: requestId);
        }
        if (offerId != null) {
          return OfferDetailScreen(offerId: offerId);
        }
        return null;
    }
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
