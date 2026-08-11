/// Tracks which chat screen is currently open to suppress duplicate toasts.
class ChatSessionRegistry {
  ChatSessionRegistry._();

  static String? _openRequestId;

  static String? get openRequestId => _openRequestId;

  static bool isOpen(String requestId) => _openRequestId == requestId;

  static void open(String requestId) => _openRequestId = requestId;

  static void close(String requestId) {
    if (_openRequestId == requestId) _openRequestId = null;
  }
}
