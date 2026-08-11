part of 'notification_cubit.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.unreadCount = 0,
    this.notifications = const [],
    this.hasMore = false,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.socketConnected = false,
    this.socketConnecting = false,
    this.socketError,
  });

  final int unreadCount;
  final List<AppNotification> notifications;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool socketConnected;
  final bool socketConnecting;
  final String? socketError;

  NotificationState copyWith({
    int? unreadCount,
    List<AppNotification>? notifications,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool? socketConnected,
    bool? socketConnecting,
    String? socketError,
  }) {
    return NotificationState(
      unreadCount: unreadCount ?? this.unreadCount,
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      socketConnected: socketConnected ?? this.socketConnected,
      socketConnecting: socketConnecting ?? this.socketConnecting,
      socketError: socketError,
    );
  }

  @override
  List<Object?> get props => [
        unreadCount,
        notifications,
        hasMore,
        loading,
        loadingMore,
        error,
        socketConnected,
        socketConnecting,
        socketError,
      ];
}
