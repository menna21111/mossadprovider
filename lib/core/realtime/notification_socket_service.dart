import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../caching/cach_helper.dart';
import '../constants/app_constants.dart';
import 'notification_socket_message.dart';

typedef SocketPayloadHandler = void Function(Map<String, dynamic> payload);
typedef SocketCloseHandler = void Function(int? code, String? reason);
typedef SocketConnectedHandler = void Function(String url);
typedef VoidCallback = void Function();

class NotificationSocketService {
  NotificationSocketService({
    required this.onMessage,
    this.onConnected,
    this.onReconnect,
    this.onClose,
  });

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;
  bool _connecting = false;
  String? _connectedUrl;
  bool _handshakeAcknowledged = false;

  final SocketPayloadHandler onMessage;
  final SocketConnectedHandler? onConnected;
  final VoidCallback? onReconnect;
  final SocketCloseHandler? onClose;

  bool get isConnected => _channel != null;
  String? get connectedUrl => _connectedUrl;
  bool get handshakeAcknowledged => _handshakeAcknowledged;

  Future<void> connect() async {
    if (_connecting || isConnected) return;
    _manualDisconnect = false;
    _connecting = true;
    _handshakeAcknowledged = false;

    final token =
        CacheHelper().getDataString(key: AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      log('[NotificationSocket] skipped: missing access token', name: 'Realtime');
      _connecting = false;
      return;
    }

    try {
      final candidates = _connectionCandidates(token);
      for (final candidate in candidates) {
        final safeUrl = _sanitizeUrl(candidate.url);
        log(
          '[NotificationSocket] connecting to $safeUrl (authHeader=${candidate.useAuthHeader})',
          name: 'Realtime',
        );
        try {
          final socket = await WebSocket.connect(
            candidate.url,
            headers: candidate.headers,
          ).timeout(const Duration(seconds: 10));

          _channel = IOWebSocketChannel(socket);
          _connectedUrl = candidate.url;
          _reconnectAttempt = 0;
          _attachListeners();
          log('[NotificationSocket] websocket upgraded: $safeUrl', name: 'Realtime');
          onConnected?.call(candidate.url);
          return;
        } catch (e) {
          log(
            '[NotificationSocket] candidate failed: $safeUrl => $e',
            name: 'Realtime',
          );
        }
      }

      log('[NotificationSocket] all candidates failed', name: 'Realtime');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  List<_SocketConnectionCandidate> _connectionCandidates(String token) {
    final urls = AppConstants.notificationSocketUrls(token);
    final candidates = <_SocketConnectionCandidate>[];

    for (final url in urls) {
      candidates.add(
        _SocketConnectionCandidate(
          url: url,
          headers: _upgradeHeaders(token, includeAuth: true),
          useAuthHeader: true,
        ),
      );
      candidates.add(
        _SocketConnectionCandidate(
          url: url,
          headers: _upgradeHeaders(token, includeAuth: false),
          useAuthHeader: false,
        ),
      );
    }

    return candidates;
  }

  Map<String, String> _upgradeHeaders(
    String token, {
    required bool includeAuth,
  }) {
    final headers = <String, String>{
      'Connection': 'Upgrade',
      'Upgrade': 'websocket',
    };
    if (includeAuth) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _attachListeners() {
    _subscription = _channel!.stream.listen(
      _handleRawMessage,
      onDone: _handleDone,
      onError: (error) {
        log('[NotificationSocket] stream error: $error', name: 'Realtime');
        _handleDone();
      },
      cancelOnError: true,
    );
  }

  void _handleRawMessage(dynamic raw) {
    final preview = raw.toString();
    log(
      '[NotificationSocket] message: ${_truncate(preview)}',
      name: 'Realtime',
    );

    final message = NotificationSocketMessage.parse(raw);
    switch (message.kind) {
      case NotificationSocketMessageKind.connectionEstablished:
        _handshakeAcknowledged = true;
        log(
          '[NotificationSocket] server ack: ${message.payload}',
          name: 'Realtime',
        );
        return;
      case NotificationSocketMessageKind.ping:
        _replyPong();
        return;
      case NotificationSocketMessageKind.pong:
        return;
      case NotificationSocketMessageKind.notification:
        final payload = message.payload;
        if (payload != null) {
          log(
            '[NotificationSocket] notification event=${payload['event']}',
            name: 'Realtime',
          );
          onMessage(payload);
        }
        return;
      case NotificationSocketMessageKind.ignored:
        return;
      case NotificationSocketMessageKind.unknown:
        log(
          '[NotificationSocket] unknown payload: ${message.payload}',
          name: 'Realtime',
        );
        return;
    }
  }

  void _replyPong() {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({'type': 'pong'}));
    log('[NotificationSocket] replied pong', name: 'Realtime');
  }

  void _handleDone() {
    final code = _channel?.closeCode;
    final reason = _channel?.closeReason;
    log(
      '[NotificationSocket] closed code=$code reason=$reason url=${_sanitizeUrl(_connectedUrl ?? '')}',
      name: 'Realtime',
    );
    onClose?.call(code, reason);
    _cleanupChannel();

    if (_manualDisconnect) return;
    if (code == 4003) return;
    if (code == 4001) {
      _manualDisconnect = true;
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer != null) return;
    final delaySeconds = [1, 2, 4, 8, 16, 30][_reconnectAttempt.clamp(0, 5)];
    _reconnectAttempt++;
    log(
      '[NotificationSocket] reconnect in ${delaySeconds}s (attempt=$_reconnectAttempt)',
      name: 'Realtime',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      _reconnectTimer = null;
      await connect();
      onReconnect?.call();
    });
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _cleanupChannel();
  }

  void _cleanupChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _connectedUrl = null;
    _handshakeAcknowledged = false;
  }

  String _sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final sanitizedQuery = Map<String, String>.from(uri.queryParameters)
      ..updateAll((key, value) {
        if (key == 'token' || key == 'access_token') return '***';
        return value;
      });
    return uri.replace(queryParameters: sanitizedQuery).toString();
  }

  String _truncate(String value, [int max = 240]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}...';
  }

  void dispose() => disconnect();
}

class _SocketConnectionCandidate {
  const _SocketConnectionCandidate({
    required this.url,
    required this.headers,
    required this.useAuthHeader,
  });

  final String url;
  final Map<String, String> headers;
  final bool useAuthHeader;
}
