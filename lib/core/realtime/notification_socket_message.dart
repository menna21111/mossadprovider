import 'dart:convert';

/// Normalizes notification WebSocket payloads from different backend shapes.
class NotificationSocketMessage {
  const NotificationSocketMessage._({
    required this.kind,
    this.payload,
  });

  final NotificationSocketMessageKind kind;
  final Map<String, dynamic>? payload;

  static NotificationSocketMessage parse(dynamic raw) {
    if (raw == null) {
      return const NotificationSocketMessage._(kind: NotificationSocketMessageKind.ignored);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return const NotificationSocketMessage._(kind: NotificationSocketMessageKind.ignored);
    }

    if (text == 'ping' || text == 'pong') {
      return NotificationSocketMessage._(
        kind: text == 'ping'
            ? NotificationSocketMessageKind.ping
            : NotificationSocketMessageKind.pong,
      );
    }

    final decoded = _decodeJson(text);
    if (decoded == null) {
      return NotificationSocketMessage._(
        kind: NotificationSocketMessageKind.unknown,
        payload: {'raw': text},
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return NotificationSocketMessage._(
        kind: NotificationSocketMessageKind.unknown,
        payload: {'raw': text},
      );
    }

    final kind = _resolveKind(decoded);
    switch (kind) {
      case NotificationSocketMessageKind.connectionEstablished:
      case NotificationSocketMessageKind.ping:
      case NotificationSocketMessageKind.pong:
        return NotificationSocketMessage._(kind: kind, payload: decoded);
      case NotificationSocketMessageKind.notification:
        return NotificationSocketMessage._(
          kind: kind,
          payload: _extractNotificationPayload(decoded),
        );
      case NotificationSocketMessageKind.ignored:
      case NotificationSocketMessageKind.unknown:
        return NotificationSocketMessage._(
          kind: kind,
          payload: decoded,
        );
    }
  }

  static dynamic _decodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static NotificationSocketMessageKind _resolveKind(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase() ?? '';
    final event = json['event']?.toString().toLowerCase() ?? '';
    final status = json['status']?.toString().toLowerCase() ?? '';
    final marker = type.isNotEmpty ? type : event;

    if (marker == 'ping') return NotificationSocketMessageKind.ping;
    if (marker == 'pong') return NotificationSocketMessageKind.pong;
    if (marker == 'connection_established' ||
        marker == 'connected' ||
        marker == 'connection_ack' ||
        status == 'connected') {
      return NotificationSocketMessageKind.connectionEstablished;
    }

    if (_looksLikeNotification(json)) {
      return NotificationSocketMessageKind.notification;
    }

    if (json['notification'] is Map ||
        json['payload'] is Map ||
        (json['data'] is Map && _looksLikeNotification(json['data'] as Map))) {
      return NotificationSocketMessageKind.notification;
    }

    return NotificationSocketMessageKind.unknown;
  }

  static bool _looksLikeNotification(Map<dynamic, dynamic> json) {
    return json.containsKey('notification_id') ||
        json.containsKey('title') ||
        json.containsKey('body') ||
        (json['event'] != null &&
            json['event'].toString().isNotEmpty &&
            json['event'].toString().toLowerCase() != 'connection_established');
  }

  static Map<String, dynamic> _extractNotificationPayload(
    Map<String, dynamic> json,
  ) {
    final notification = json['notification'];
    if (notification is Map<String, dynamic>) {
      return Map<String, dynamic>.from(notification);
    }

    final payload = json['payload'];
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }

    final data = json['data'];
    if (data is Map<String, dynamic> && _looksLikeNotification(data)) {
      return Map<String, dynamic>.from(data);
    }

    return Map<String, dynamic>.from(json);
  }
}

enum NotificationSocketMessageKind {
  connectionEstablished,
  notification,
  ping,
  pong,
  ignored,
  unknown,
}
