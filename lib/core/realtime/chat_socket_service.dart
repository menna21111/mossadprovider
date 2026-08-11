import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../caching/cach_helper.dart';
import '../constants/app_constants.dart';

typedef ChatPayloadHandler = void Function(Map<String, dynamic> payload);
typedef ChatCloseHandler = void Function(int? code, String? reason);
typedef ChatConnectedHandler = void Function(String url);

class ChatSocketService {
  ChatSocketService({
    required this.requestId,
    required this.onMessage,
    this.onConnected,
    this.onClose,
  });

  final String requestId;
  final ChatPayloadHandler onMessage;
  final ChatConnectedHandler? onConnected;
  final ChatCloseHandler? onClose;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;
  bool _connecting = false;
  String? _connectedUrl;

  bool get isConnected => _channel != null;
  String? get connectedUrl => _connectedUrl;

  Future<void> connect() async {
    if (_connecting || isConnected) return;
    _manualDisconnect = false;
    _connecting = true;

    final token =
        CacheHelper().getDataString(key: AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      log('[ChatSocket] skipped: missing access token', name: 'Realtime');
      _connecting = false;
      return;
    }

    try {
      final candidates = _connectionCandidates(token);
      for (final candidate in candidates) {
        final safeUrl = _sanitizeUrl(candidate.url);
        log(
          '[ChatSocket] connecting to $safeUrl (authHeader=${candidate.useAuthHeader})',
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
          log('[ChatSocket] websocket upgraded: $safeUrl', name: 'Realtime');
          onConnected?.call(candidate.url);
          return;
        } catch (e) {
          log(
            '[ChatSocket] candidate failed: $safeUrl => $e',
            name: 'Realtime',
          );
        }
      }
      log('[ChatSocket] all candidates failed', name: 'Realtime');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  List<_ChatConnectionCandidate> _connectionCandidates(String token) {
    final urls = AppConstants.chatSocketUrls(requestId, token);
    final candidates = <_ChatConnectionCandidate>[];

    for (final url in urls) {
      candidates.add(
        _ChatConnectionCandidate(
          url: url,
          headers: _upgradeHeaders(token, includeAuth: true),
          useAuthHeader: true,
        ),
      );
      candidates.add(
        _ChatConnectionCandidate(
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
      (raw) {
        final preview = raw.toString();
        log(
          '[ChatSocket] message: ${_truncate(preview)}',
          name: 'Realtime',
        );
        try {
          final decoded = jsonDecode(raw.toString());
          if (decoded is Map<String, dynamic>) {
            onMessage(decoded);
          }
        } catch (e) {
          log('[ChatSocket] parse error: $e', name: 'Realtime');
        }
      },
      onDone: _handleDone,
      onError: (error) {
        log('[ChatSocket] stream error: $error', name: 'Realtime');
        _handleDone();
      },
      cancelOnError: true,
    );
  }

  void _handleDone() {
    final code = _channel?.closeCode;
    final reason = _channel?.closeReason;
    log(
      '[ChatSocket] closed code=$code reason=$reason',
      name: 'Realtime',
    );
    onClose?.call(code, reason);
    _cleanupChannel();

    if (_manualDisconnect) return;
    if (code == 4001 || code == 4003) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer != null) return;
    final delaySeconds = [1, 2, 4, 8, 16, 30][_reconnectAttempt.clamp(0, 5)];
    _reconnectAttempt++;
    log(
      '[ChatSocket] reconnect in ${delaySeconds}s (attempt=$_reconnectAttempt)',
      name: 'Realtime',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      _reconnectTimer = null;
      await connect();
    });
  }

  /// Sends chat text over WebSocket. Returns `true` if the frame was written.
  bool sendMessage(String message) {
    final text = message.trim();
    if (_channel == null || text.isEmpty) {
      log('[ChatSocket] send skipped: not connected', name: 'Realtime');
      return false;
    }

    final payload = jsonEncode({'message': text});
    _channel!.sink.add(payload);
    log('[ChatSocket] sent: $payload', name: 'Realtime');
    return true;
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

class _ChatConnectionCandidate {
  const _ChatConnectionCandidate({
    required this.url,
    required this.headers,
    required this.useAuthHeader,
  });

  final String url;
  final Map<String, String> headers;
  final bool useAuthHeader;
}
