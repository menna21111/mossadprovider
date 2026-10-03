import 'package:equatable/equatable.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/failure.dart';
import '../../data/models/app_notification.dart';
import '../../data/notifications_repository.dart';
import '../../../../core/realtime/notification_socket_service.dart';
import '../../../../core/realtime/chat_session_registry.dart';
import '../../../../app/navigator_key.dart';
import '../../../../app/functions.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/services/notification/in_app_alert_service.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this._repository) : super(const NotificationState());

  final NotificationsRepository _repository;
  NotificationSocketService? _socket;

  /// Fired when socket receives `new_custom_request` — refresh custom requests tab.
  void Function()? onNewCustomRequest;
  void Function()? onOfferAccepted;
  void Function()? onNewChatMessage;
  void Function(Map<String, dynamic> payload)? onDuePaymentRequired;
  void Function()? onAccountUnblocked;

  Future<void> startRealtime() async {
    await _socket?.disconnect();
    emit(state.copyWith(
      socketConnecting: true,
      socketConnected: false,
      socketError: null,
    ));

    _socket = NotificationSocketService(
      onMessage: _handleSocketMessage,
      onConnected: (_) {
        emit(state.copyWith(
          socketConnected: true,
          socketConnecting: false,
          socketError: null,
        ));
      },
      onClose: (code, reason) {
        emit(state.copyWith(
          socketConnected: false,
          socketConnecting: false,
          socketError: reason ?? (code != null ? 'code $code' : 'disconnected'),
        ));
      },
      onReconnect: syncAfterReconnect,
    );
    await _socket!.connect();

    if (!_socket!.isConnected) {
      emit(state.copyWith(
        socketConnected: false,
        socketConnecting: false,
        socketError: 'failed to connect',
      ));
    }

    await refreshUnreadCount();
  }

  Future<void> stopRealtime() async {
    await _socket?.disconnect();
    _socket = null;
    emit(state.copyWith(
      socketConnected: false,
      socketConnecting: false,
    ));
  }

  Future<void> syncAfterReconnect() async {
    await refreshUnreadCount();
    await loadNotifications(refresh: true, isRead: false);
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (_) {}
  }

  Future<void> loadNotifications({
    bool refresh = false,
    bool? isRead,
  }) async {
    if (state.loadingMore && !refresh) return;

    emit(state.copyWith(
      loading: refresh || state.notifications.isEmpty,
      loadingMore: !refresh && state.notifications.isNotEmpty,
      error: null,
    ));

    try {
      final offset = refresh ? 0 : state.notifications.length;
      final page = await _repository.getNotifications(
        isRead: isRead,
        offset: offset,
      );

      final merged = refresh
          ? page.results
          : [...state.notifications, ...page.results];

      emit(state.copyWith(
        notifications: merged,
        hasMore: page.hasMore,
        loading: false,
        loadingMore: false,
      ));
    } on ServerFailure catch (e) {
      emit(state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.errMessage,
      ));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return AppNotification(
            id: n.id,
            event: n.event,
            title: n.title,
            body: n.body,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
            readAt: n.readAt,
          );
        }
        return n;
      }).toList();
      emit(state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ));
    } on ServerFailure catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      emit(state.copyWith(unreadCount: 0));
      await loadNotifications(refresh: true);
    } on ServerFailure catch (_) {}
  }

  void _handleSocketMessage(Map<String, dynamic> payload) {
    final event = payload['event']?.toString() ?? '';

    if (event == 'new_chat_message') {
      final requestId = payload['request_id']?.toString();
      if (requestId != null && ChatSessionRegistry.isOpen(requestId)) {
        return;
      }
    }

    final notification = AppNotification.fromSocket(payload);
    if (notification.id.isNotEmpty || notification.title.isNotEmpty) {
      emit(state.copyWith(
        unreadCount: state.unreadCount + 1,
        notifications: [notification, ...state.notifications],
      ));
    } else {
      emit(state.copyWith(unreadCount: state.unreadCount + 1));
    }

    _showToast(payload);
    InAppAlertService.playIncoming();
    _dispatchSideEffects(event, payload);
  }

  void _showToast(Map<String, dynamic> payload) {
    final title = payload['title']?.toString();
    final body = payload['body']?.toString() ??
        payload['description_preview']?.toString();
    final message = [title, body]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join('\n');
    if (message.isEmpty) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      AppFunctions.showsToast(message, MosaedColors.primary, context);
    });
  }

  void _dispatchSideEffects(String event, Map<String, dynamic> payload) {
    switch (event) {
      case 'new_custom_request':
        onNewCustomRequest?.call();
        break;
      case 'offer_accepted':
        onOfferAccepted?.call();
        break;
      case 'new_chat_message':
        onNewChatMessage?.call();
        break;
      case 'due_payment_required':
        onDuePaymentRequired?.call(payload);
        break;
      case 'account_unblocked':
        onAccountUnblocked?.call();
        break;
    }
  }

  void handlePushPayload(Map<String, dynamic> payload) {
    _handleSocketMessage(payload);
  }

  @override
  Future<void> close() async {
    await stopRealtime();
    return super.close();
  }
}
